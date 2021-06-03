/*****************************************************************************************************
 * Copyright 2014-2016 SPECURE GmbH
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *****************************************************************************************************/

import Foundation

class RMBTConcurencyGroup {
    var identifier: UInt = 0
    private(set) var testExecutors: [QOSTestExecutorProtocol] = []
    
    var passedExecutors: Int = 0
    
    var percent: Float {
        return Float(self.passedExecutors) / Float(self.testExecutors.count)
    }
    
    let mutualQuery = DispatchQueue(label: "Add executors")
    
    func addTestExecutor(testExecutor: QOSTestExecutorProtocol) {
        mutualQuery.sync {
            testExecutors.append(testExecutor)
        }
    }
    
    func removeTestExecutor(testExecutor: QOSTestExecutorProtocol) {
        mutualQuery.sync {
            if let index = testExecutors.firstIndex(where: { (executor) -> Bool in
                return testExecutor === executor
            }) {
                testExecutors.remove(at: index)
            }
        }
    }
    
    func countExecutors(of type: QosMeasurementType) -> (passed: Int, total: Int) {
        var totalCount = 0
        var passedCount = 0
        for executor in testExecutors {
            if executor.testObjectType() == type {
                totalCount += 1
                if executor.testExecutorHasFinished() {
                    passedCount += 1
                }
            }
        }
        
        return (passedCount, totalCount)
    }
}

///
open class QualityOfServiceTest: NSObject {

    ///
    public typealias ConcurrencyGroup = UInt

    ///
    public typealias JsonObjectivesType = [String: [[String: Any]]]

    //

    ///
    private let executorQueue = DispatchQueue(label: "com.specure.rmbt.executorQueue")
    
    private let delegateQueue = DispatchQueue(label: "com.specure.rmbt.delegateQueue", attributes: DispatchQueue.Attributes.concurrent)

    private let mutualExclusionQueue = DispatchQueue(label: "com.specure.rmbt.qos.mutualExclusionQueue")
    
    ///
    private let qosQueue = DispatchQueue(label: "com.specure.rmbt.qosQueue", attributes: DispatchQueue.Attributes.concurrent)

    var concurencyGroups: [RMBTConcurencyGroup] = []
    
    ///
    open weak var delegate: QualityOfServiceTestDelegate?
    
    ///
    var isPartOfMainTest = false

    ///
    private let testToken: String

    ///
    private let measurementUuid: String

    ///
    private let speedtestStartTime: UInt64

    ///
    private var testCount: UInt16 = 0

    ///
    private var currentTestCount: UInt16 = 0

    ///
    private var activeTestsInConcurrencyGroup = 0

    ///
    private var controlConnectionMap: [String: QOSControlConnection] = [:]

    ///
    private var qosTestConcurrencyGroupMap: [ConcurrencyGroup: [QOSTest]] = [:]
    private var qosTestExecutors: [String: QOSTestExecutorProtocol] = [:]

    ///
    private var testTypeCountMap: [QosMeasurementType: UInt16] = [:]

    ///
    private var sortedConcurrencyGroups: [ConcurrencyGroup] = []

    ///
    private var resultArray: [QOSTestResult] = []

    ///
    private var stopped = false

    //
    deinit {
        defer {
            if self.stopped == false {
                self.closeAllControlConnections()
            }
        }
    }
    ///
    public init(testToken: String, measurementUuid: String, speedtestStartTime: UInt64, isPartOfMainTest: Bool) {
        self.testToken = testToken
        self.measurementUuid = measurementUuid
        self.speedtestStartTime = speedtestStartTime
        self.isPartOfMainTest = isPartOfMainTest

        Log.logger.debug("QualityOfServiceTest initialized with test token: \(testToken) at start time \(speedtestStartTime)")
    }

    ///
    open func start() {
        if !stopped {
            qosQueue.async {
                self.fetchQOSTestParameters()
            }
        }
    }

    ///
    open func stop() {
        Log.logger.debug("ABORTING QOS TEST")

        self.stopped = true
        DispatchQueue.main.async {
            // close all control connections
            self.closeAllControlConnections()

            // inform delegate
                self.delegate?.qualityOfServiceTestDidStop(self)
                return
        }
    }

    //

    ///
    private func fetchQOSTestParameters() {
        if stopped {
            return
        }

        let controlServer = ControlServer.sharedControlServer

        controlServer.requestQosMeasurement(measurementUuid, success: { [weak self] response in
            self?.qosQueue.async {
                if self?.isPartOfMainTest == true {
                    if let jitterParams = response.objectives?[QosMeasurementType.JITTER.rawValue] {
                        if let firstParams = jitterParams.first {
                            response.objectives = [QosMeasurementType.VOIP.rawValue: [firstParams]]
                        }
                    }
                }
                else {
                    response.objectives?[QosMeasurementType.JITTER.rawValue] = nil
//                    response.objectives?[QosMeasurementType.UDP.rawValue] = nil
//                    response.objectives?[QosMeasurementType.TCP.rawValue] = nil
//                    response.objectives?[QosMeasurementType.HttpProxy.rawValue] = nil
//                    response.objectives?[QosMeasurementType.NonTransparentProxy.rawValue] = nil
//                    response.objectives?[QosMeasurementType.WEBSITE.rawValue] = nil
//                    response.objectives?[QosMeasurementType.DNS.rawValue] = nil
//                    response.objectives?[QosMeasurementType.VOIP.rawValue] = nil
//                    response.objectives?[QosMeasurementType.TRACEROUTE.rawValue] = nil
                }
                self?.continueWithQOSParameters(response)
            }
        }) { [weak self] error in
            Log.logger.debug("ERROR fetching qosTestRequest")

            self?.fail(nil) // TODO: error message...
        }
    }

    ///
    private func continueWithQOSParameters(_ responseObject: QosMeasurmentResponse) {
        if stopped {
            return
        }

        // call didStart delegate method // TODO: right place here?
        DispatchQueue.main.async {
            self.delegate?.qualityOfServiceTestDidStart(self)
            return
        }

        parseRequestResult(responseObject)
        createTestTypeCountMap()
        // openAllControlConnections() // open all control connections before tests    
        self.runQOSTests()
        
    }

    func findNextTestExecutor(in group: RMBTConcurencyGroup) -> QOSTestExecutorProtocol? {
        for testExecutor in group.testExecutors {
            if !testExecutor.testExecutorHasFinished() {
                return testExecutor
            }
        }
        
        return nil
    }
    
    func findNextConcurencyGroup() -> RMBTConcurencyGroup? {
        for group in concurencyGroups {
            if group.passedExecutors != group.testExecutors.count {
                return group
            }
        }
        
        return nil
    }
    
    func findConcurencyGroup(with id: UInt) -> RMBTConcurencyGroup {
        for group in concurencyGroups {
            if group.identifier == id {
                return group
            }
        }
        
        let group = RMBTConcurencyGroup()
        group.identifier = id
        concurencyGroups.append(group)
        return group
    }
    
    ///
    private func parseRequestResult(_ responseObject: QosMeasurmentResponse) {
        if stopped {
            return
        }

        guard let objectives = responseObject.objectives else { return }
        
        for (objectiveType, objectiveValues) in objectives {
            for (objectiveParams) in objectiveValues {
                if let qosTest = QOSFactory.createQOSTest(objectiveType, params: objectiveParams),
                    let testExecutor = QOSFactory.createTestExecutor(qosTest, delegateQueue: delegateQueue, speedtestStartTime: speedtestStartTime) {
                    let group = self.findConcurencyGroup(with: qosTest.concurrencyGroup)
                    group.addTestExecutor(testExecutor: testExecutor)
                    testCount += 1
                    if isPartOfMainTest == true && objectiveType == QosMeasurementType.VOIP.rawValue {
                        testExecutor.setProgressCallback { [weak self] (_, percent) in
                            guard let strongSelf = self else { return }
                            strongSelf.delegate?.qualityOfServiceTest(strongSelf, didProgressToValue: percent)
                        }
                    }
                    testExecutor.setCurrentTestToken(self.testToken)
                }
            }
        }
        
        self.concurencyGroups = self.concurencyGroups.sorted(by: { (group1, group2) -> Bool in
            return group1.identifier < group2.identifier
        })
        return
        // loop through objectives

        // objective type is TCP, UDP, etc.
        // objective values are arrays of dictionaries for each test
//        for (objectiveType, objectiveValues) in objectives {
//
//            // loop each test
//            for (objectiveParams) in objectiveValues {
//                Log.logger.verbose("-----")
//                Log.logger.verbose("\(objectiveType): \(objectiveParams)")
//                Log.logger.verbose("-------------------")
//
//                // try to create qos test object from params
//                if let qosTest = QOSFactory.createQOSTest(objectiveType, params: objectiveParams) {
//                    ///////////// ONT
//                    if isPartOfMainTest {
//
//                        if let type = QosMeasurementType(rawValue: objectiveType) {
//
//                            if type == .VOIP {
//
//                                Log.logger.debug("created VOIP test as the main test: \(qosTest)")
//
//                                var concurrencyGroupArray: [QOSTest]? = qosTestConcurrencyGroupMap[qosTest.concurrencyGroup]
//                                if concurrencyGroupArray == nil {
//                                    concurrencyGroupArray = []
//                                }
//
//                                concurrencyGroupArray?.append(qosTest)
//                                qosTestConcurrencyGroupMap[qosTest.concurrencyGroup] = concurrencyGroupArray // is this line needed? wasn't this passed by reference?
//
//                                // increase test count
//                                testCount += 1
//                            }
//                        }
//
//                    } else {
//
//                        if let type = QosMeasurementType(rawValue: objectiveType) {
//                            if type != .JITTER {
//                                Log.logger.debug("created qos test: \(qosTest)")
//
//                                var concurrencyGroupArray: [QOSTest]? = qosTestConcurrencyGroupMap[qosTest.concurrencyGroup]
//                                if concurrencyGroupArray == nil {
//                                    concurrencyGroupArray = [QOSTest]()
//                                }
//
//                                concurrencyGroupArray!.append(qosTest)
//                                qosTestConcurrencyGroupMap[qosTest.concurrencyGroup] = concurrencyGroupArray // is this line needed? wasn't this passed by reference?
//
//                                // increase test count
//                                testCount += 1
//                            }
//                        }
//                    }
//
//
//
//                } else {
//                    Log.logger.debug("unimplemented/unknown qos type: \(objectiveType)")
//                }
//            }
//        }
//
//        currentTestCount = testCount
//
//        // create sorted array of keys to let the concurrencyGroups increase
//        sortedConcurrencyGroups = Array(qosTestConcurrencyGroupMap.keys).sorted(by: <)
//
//        Log.logger.debug("sorted concurrency groups: \(self.sortedConcurrencyGroups)")
    }

    ///
    private func createTestTypeCountMap() {
        if stopped {
            return
        }

        let testTypeArray = NSMutableSet()
        
        for group in concurencyGroups {
            for executor in group.testExecutors {
                testTypeArray.add(executor.testObjectType())
            }
        }
        
        DispatchQueue.main.async {
            self.delegate?.qualityOfServiceTest(self, didFetchTestTypes: testTypeArray.map({ (type) -> String in
                if let type = type as? QosMeasurementType {
                    return type.rawValue
                }
                return ""
            }))
        }
        return
//        var testTypeSortDictionary: [QosMeasurementType: ConcurrencyGroup] = [:]
//
//        // fill testTypeCount map (used for displaying the finished test types in ui)
//        for (cg, testArray) in qosTestConcurrencyGroupMap { // loop each concurrency group
//            for test in testArray { // loop the tests inside each concurrency group
//                let testType = test.getType()
//
//                var count: UInt16? = testTypeCountMap[testType!]
//                if count == nil {
//                    count = 0
//                }
//
//                count! += 1
//
//                testTypeCountMap[testType!] = count!
//
//                //////
//
//                if testTypeSortDictionary[testType!] == nil {
//                    testTypeSortDictionary[testType!] = cg
//                }
//            }
//        }
//
//        // get test types and sort them according to their first execution
//        var testTypeArray = [QosMeasurementType](self.testTypeCountMap.keys)
//        testTypeArray.sort { (lhs, rhs) -> Bool in
//            guard let firstType = testTypeSortDictionary[lhs],
//                let secondType = testTypeSortDictionary[rhs]
//                else {
//                    return false
//            }
//            return firstType < secondType
//        }
//
//        // call didFetchTestTypes delegate method
//        DispatchQueue.main.async {
//            self.delegate?.qualityOfServiceTest(self, didFetchTestTypes: testTypeArray.map({ (type) -> String in
//                return type.rawValue
//            }))
//            return
//        }
//
//        Log.logger.debug("TEST TYPE COUNT MAP: \(self.testTypeCountMap)")
    }

    ///
    private func runQOSTests() {
        Log.logger.debug("RUN QOS TESTS (stopped: \(self.stopped))")

        if stopped {
            return
        }

        // start with first concurrency group
        runTestsOfNextConcurrencyGroup()
    }

    private func runNextTest(in concurencyGroup: RMBTConcurencyGroup) {
        if stopped {
            return
        }
        if let testExecutor = self.findNextTestExecutor(in: concurencyGroup) {
//            for testExecutor in concurencyGroup.testExecutors {
                // execute test
                executorQueue.async {
                    testExecutor.execute { [weak self, weak concurencyGroup] (testResult: QOSTestResult) in
                        self?.mutualExclusionQueue.sync { [weak self] in
                            self?.resultArray.append(testResult)
                            concurencyGroup?.passedExecutors += 1
                            self?.checkProgress()
                            if let concurencyGroup = concurencyGroup {
                                self?.runNextTest(in: concurencyGroup)
                            }
//                            if concurencyGroup?.passedExecutors == concurencyGroup?.testExecutors.count {
//                                self?.closeAllControlConnections()
//                                self?.mutualExclusionQueue.asyncAfter(deadline: .now() + 0.5, execute: {
//                                    self?.controlConnectionMap = [:]
//                                    self?.runTestsOfNextConcurrencyGroup()
//                                })
//                            }
                        }
                    }
                }
//            }
        }
        else {
            self.closeAllControlConnections()
            self.controlConnectionMap = [:]
            self.runTestsOfNextConcurrencyGroup()
        }
    }
    ///
    private func runTestsOfNextConcurrencyGroup() {
        if stopped {
            return
        }

        if let concurencyGroup = self.findNextConcurencyGroup() {
            for testExecutor in concurencyGroup.testExecutors {
                if testExecutor.needsControlConnection() {
                    let qosTest = testExecutor.getTestObject()
                    
                    if let controlConnection = getControlConnection(qosTest) {
                        if !testExecutor.needsCustomTimeoutHandling() {
                            controlConnection.setTimeout(QOS_CONTROL_CONNECTION_TIMEOUT_NS)
                        }
                        testExecutor.setControlConnection(controlConnection)
                    }
                    else {
                        // don't do this test
                        Log.logger.info("skipping test because it needs control connection but we don't have this connection. \(qosTest)")
                        concurencyGroup.removeTestExecutor(testExecutor: testExecutor)
                        testCount -= 1
                        continue
                    }
                    
                }
            }
            
//            self.runNextTest(in: concurencyGroup)
//            return
            
            for testExecutor in concurencyGroup.testExecutors {
                // execute test
                executorQueue.async {
                    testExecutor.execute { [weak self, weak concurencyGroup] (testResult: QOSTestResult) in
                        self?.mutualExclusionQueue.sync { [weak self] in
                            self?.resultArray.append(testResult)
                            concurencyGroup?.passedExecutors += 1
                            self?.checkProgress()
                            if concurencyGroup?.passedExecutors == concurencyGroup?.testExecutors.count {
                                self?.mutualExclusionQueue.asyncAfter(deadline: .now() + 0.5, execute: {
                                    self?.runTestsOfNextConcurrencyGroup()
                                })
                            }
                        }
                    }
                }
            }
        }
        else {
            self.finalizeQOSTests()
        }
//        if sortedConcurrencyGroups.count > 0 {
//            let concurrencyGroup = sortedConcurrencyGroups.remove(at: 0) // what happens if empty?
//
//            Log.logger.debug("run tests of next concurrency group: \(concurrencyGroup) (\(self.sortedConcurrencyGroups.count))")
//
//            if let testArray = qosTestConcurrencyGroupMap[concurrencyGroup] {
//
//                // set count of tests
//                activeTestsInConcurrencyGroup = testArray.count
//
//                // calculate control connection timeout (TODO: improve)
//                // var controlConnectionTimeout: UInt64 = 0
//                // for qosTest in testArray {
//                //    controlConnectionTimeout += qosTest.timeout
//                // }
//                /////
//
//                // loop test array
//                for qosTest in testArray {
//                    if stopped {
//                        return
//                    }
//
//                    // get previously opened control connection
//                    let controlConnection = getControlConnection(qosTest) // blocking if new connection has to be established
//
//                    // get test executor
//                    if let testExecutor = QOSFactory.createTestExecutor(qosTest, controlConnection: controlConnection, delegateQueue: executorQueue, speedtestStartTime: speedtestStartTime) {
//                        // TODO: which queue?
//
//                        let key = UUID().uuidString
//                        self.qosTestExecutors[key] = testExecutor //Need keep it in memory
//
//                        // set test token (TODO: IMPROVE)
//                        testExecutor.setCurrentTestToken(self.testToken)
//
//                        if testExecutor.needsControlConnection() {
//                            // set control connection timeout (TODO: compute better! (not all tests may use same control connection))
//                            Log.logger.debug("setting control connection timeout to \(nsToMs(qosTest.timeout)) ms")
//                            controlConnection.setTimeout(qosTest.timeout)
//
//                            // TODO: DETERMINE IF TEST NEEDS CONTROL CONNECTION
//                            // IF IT NEEDS IT, AND CONTROL CONNECTION CONNECT FAILED THEN SKIP THIS TEST AND DON'T SEND RESULT TO SERVER
//                            if !controlConnection.connected {
//                                // don't do this test
//                                Log.logger.info("skipping test because it needs control connection but we don't have this connection. \(qosTest)")
//
//                                self.mutualExclusionQueue.sync {
//                                    self.qosTestFinishedWithResult(qosTest.getType(), withTestResult: nil) // no result because test didn't run
//                                }
//
//                                continue
//                            }
//                        }
//
//                        Log.logger.debug("starting execution of test: \(qosTest)")
//
//                        // execute test
//                        self.executorQueue.async {
//                            testExecutor.execute { [weak self] (testResult: QOSTestResult) in
//
//                                self?.mutualExclusionQueue.sync { [weak self] in
//                                    self?.qosTestExecutors[key] = nil
//                                    self?.qosTestFinishedWithResult(testResult.testType, withTestResult: testResult)
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//        else {
//            fail(nil)
//        }
    }

    ///
    private func qosTestFinishedWithResult(_ testType: QosMeasurementType, withTestResult testResult: QOSTestResult?) {
        if stopped {
            return
        }

        Log.logger.debug("qos test finished with result: \(String(describing: testResult))")

        if let testResult = testResult {

            if testResult.fatalError {
                // TODO: quit whole test due to fatal error
                // !!

                // TODO: dispatch delegate method
                self.fail(nil) // TODO: error message...
            }

            // add result to result map
            resultArray.append(testResult)
        }

        checkProgress()
        checkTypeCount(testType)
//        checkTestState()
    }

    ///
    private func checkProgress() {
        if stopped {
            return
        }

//        if self.currentTestCount > 0 {
//        // decrement test counts
//            self.currentTestCount -= 1
//        }
//        // check for progress
//        let testsLeft = self.testCount - self.currentTestCount
//        let percent: Float = Float(testsLeft) / Float(self.testCount)

        var percent: Float = 0.0
        for group in concurencyGroups {
            percent += group.percent
        }
        
        percent /= Float(concurencyGroups.count)
        Log.logger.debug("QOS: increasing progress to \(percent)")

        DispatchQueue.main.async {
            self.delegate?.qualityOfServiceTest(self, didProgressToValue: percent)
            return
        }
    }

    ///
    private func checkTypeCount(_ testType: QosMeasurementType) {
        if stopped {
            return
        }

        var totalTests: Int = 0
        var passedTests: Int = 0
        for group in concurencyGroups {
            let counts = group.countExecutors(of: testType)
            totalTests += counts.total
            passedTests += counts.passed
        }
        
        if totalTests == passedTests {
            DispatchQueue.main.async {
                self.delegate?.qualityOfServiceTest(self, didFinishTestType: testType.rawValue)
            }
        }
        
//        // check for finished test type
//        if let count = self.testTypeCountMap[testType] {
//            if count > 0 {
//                self.testTypeCountMap[testType] = count - 1
//            }
//            if count == 0 {
//
//                Log.logger.debug("QOS: finished test type: \(testType)")
//
//                DispatchQueue.main.async {
//                    self.delegate?.qualityOfServiceTest(self, didFinishTestType: testType.rawValue)
//                    return
//                }
//            }
//        }
    }

    ///
    private func checkTestState() {
        if stopped {
            return
        }

        activeTestsInConcurrencyGroup -= 1

        if activeTestsInConcurrencyGroup == 0 {
            // all tests in concurrency group finished
            // -> go on with next concurrency group

            if sortedConcurrencyGroups.count > 0 {
                // there are more concurrency groups (and tests)

                self.qosQueue.async {
                    self.runTestsOfNextConcurrencyGroup()
                }
            } else {
                // all concurrency groups finished
                self.qosQueue.async {
                    self.finalizeQOSTests()
                }
            }
        }
    }

    ///
    private func finalizeQOSTests() {
        if stopped {
            return
        }

        Log.logger.debug("ALL FINISHED")

        closeAllControlConnections()

        // submit results
        submitQOSTestResults()
    }

    ///
    private func getControlConnection(_ qosTest: QOSTest) -> QOSControlConnection? {
        // determine control connection
        let controlConnectionKey: String = "\(qosTest.serverAddress)_\(qosTest.serverPort)"

        // TODO: make instantiation of control connection synchronous with locks!
        var conn: QOSControlConnection? = self.controlConnectionMap[controlConnectionKey]
        if conn == nil {
            Log.logger.debug("\(controlConnectionKey): trying to open new control connection")
            // Log.logger.debug("NO CONTROL CONNECTION PRESENT FOR \(controlConnectionKey), creating a new one")
            Log.logger.debug("\(controlConnectionKey): BEFORE LOCK")

            // TODO: fail after timeout if qos server not available

            conn = QOSControlConnection(testToken: testToken)
            // conn.delegate = self
    
            controlConnectionMap[controlConnectionKey] = conn
        } else {
            Log.logger.debug("\(controlConnectionKey): control connection already opened")
        }

        if conn?.connected == false {
            // reconnect
            let isConnected = conn?.connect(qosTest.serverAddress, onPort: qosTest.serverPort)
            if isConnected == false {
                controlConnectionMap[controlConnectionKey] = nil
                conn = nil
            }
        }

        return conn
    }

    ///
    private func openAllControlConnections() {
        Log.logger.info("opening all control connections")

        for concurrencyGroup in self.sortedConcurrencyGroups {
            if let testArray = qosTestConcurrencyGroupMap[concurrencyGroup] {
                for qosTest in testArray {
                    // dispatch_sync(mutualExclusionQueue) {
                        /* let controlConnection = */_ = self.getControlConnection(qosTest)
                        // Log.logger.debug("opened control connection for qosTest \(qosTest)")
                    // }
                }
            }
        }
    }

    ///
    private func closeAllControlConnections() {
        Log.logger.info("closing all control connections")

        // TODO: if everything is done: close all control connections
        for (_, controlConnection) in self.controlConnectionMap {
            Log.logger.debug("closing control connection \(controlConnection)")
            controlConnection.disconnect()
        }
        
    }

    ///////////////

    ///
    private func fail(_ error: NSError?) {
        if stopped {
            return
        }

        stop()

        DispatchQueue.main.async {
            self.delegate?.qualityOfServiceTest(self, didFailWithError: error)
            return
        }
    }

    ///
    private func success() {
        if stopped {
            return
        }
        
        DispatchQueue.main.async {
            self.closeAllControlConnections()
            self.delegate?.qualityOfServiceTest(self, didFinishWithResults: self.resultArray)
            return
        }
    }

    ////////////////////////////////////////////

    ///
    private func submitQOSTestResults() {
        if stopped {
            return
        }

        var _testResultArray: [QOSTestResults] = []

        for testResult in resultArray { // TODO: resultArray == _testResultArray? just use resultArray?
            if !testResult.isEmpty() {
                _testResultArray.append(testResult.resultDictionary)
            }
        }

        print("SUBMIT RESULTS")
        print(_testResultArray)
        // don't send results if all results are empty (e.g. only tcp tests and no control connection) or added additional test as part of the main test group
        if _testResultArray.isEmpty || self.isPartOfMainTest {
            // inform delegate
            success()

            return
        }

        //

        let qosMeasurementResult = QosMeasurementResultRequest()
        qosMeasurementResult.measurementUuid = measurementUuid
        qosMeasurementResult.testToken = testToken
        qosMeasurementResult.time = NSNumber(value: UInt64.currentTimeMillis()).intValue // currently unused on server!
        qosMeasurementResult.qosResultList = _testResultArray

        let controlServer = ControlServer.sharedControlServer

        controlServer.submitQosMeasurementResult(qosMeasurementResult, success: { [weak self] response in
            Log.logger.debug("QOS TEST RESULT SUBMIT SUCCESS")

            // now the test has finished...succeeding methods should go here
            self?.success()
        }) { [weak self] error in
            Log.logger.debug("QOS TEST RESULT SUBMIT ERROR: \(error)")

            // here the test failed...
            self?.fail(error as NSError?)
        }
    }

}
