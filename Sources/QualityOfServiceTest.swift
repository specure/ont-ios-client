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
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


///
open class QualityOfServiceTest {

    ///
    public typealias ConcurrencyGroup = UInt

    ///
    public typealias JsonObjectivesType = [String: [[String: AnyObject]]]

    //

    ///
    fileprivate let executorQueue = DispatchQueue(label: "com.specure.rmbt.executorQueue", attributes: DispatchQueue.Attributes.concurrent)

    ///
    fileprivate let qosQueue = DispatchQueue(label: "com.specure.rmbt.qosQueue", attributes: DispatchQueue.Attributes.concurrent)

    ///
    fileprivate let mutualExclusionQueue = DispatchQueue(label: "com.specure.rmbt.qos.mutualExclusionQueue", attributes: [])

    ///
    open var delegate: QualityOfServiceTestDelegate?

    ///
    fileprivate let testToken: String

    ///
    fileprivate let measurementUuid: String

    ///
    fileprivate let speedtestStartTime: UInt64

    ///
    fileprivate var testCount: UInt16 = 0

    ///
    fileprivate var currentTestCount: UInt16 = 0

    ///
    fileprivate var activeTestsInConcurrencyGroup = 0

    ///
    fileprivate var controlConnectionMap = [String: QOSControlConnection]()

    ///
    fileprivate var qosTestConcurrencyGroupMap = [ConcurrencyGroup: [QOSTest]]()

    ///
    fileprivate var testTypeCountMap = [QOSMeasurementType: UInt16]()

    ///
    fileprivate var sortedConcurrencyGroups = [ConcurrencyGroup]()

    ///
    fileprivate var resultArray = [QOSTestResult]()

    ///
    fileprivate var stopped = false

    //

    ///
    public init(testToken: String, measurementUuid: String, speedtestStartTime: UInt64) {
        self.testToken = testToken
        self.measurementUuid = measurementUuid
        self.speedtestStartTime = speedtestStartTime

        logger.debug("QualityOfServiceTest initialized with test token: \(testToken) at start time \(speedtestStartTime)")
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
        logger.debug("ABORTING QOS TEST")

        mutualExclusionQueue.sync {
            self.stopped = true

            // close all control connections
            self.closeAllControlConnections()

            // inform delegate
            DispatchQueue.main.async {
                self.delegate?.qualityOfServiceTestDidStop(self)
                return
            }
        }
    }

    //

    ///
    fileprivate func fetchQOSTestParameters() {
        if stopped {
            return
        }

        let controlServer = ControlServer.sharedControlServer

        controlServer.requestQosMeasurement(measurementUuid, success: { response in
            self.qosQueue.async {
                self.continueWithQOSParameters(response)
            }
        }) { error in
            logger.debug("ERROR fetching qosTestRequest")

            self.fail(nil) // TODO: error message...
        }
    }

    ///
    fileprivate func continueWithQOSParameters(_ responseObject: QosMeasurmentResponse) {
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
        runQOSTests()
    }

    ///
    fileprivate func parseRequestResult(_ responseObject: QosMeasurmentResponse) {
        if stopped {
            return
        }

        // loop through objectives
        if let objectives = responseObject.objectives {

            // objective type is TCP, UDP, etc.
            // objective values are arrays of dictionaries for each test
            for (objectiveType, objectiveValues) in objectives {

                // loop each test
                for (objectiveParams) in objectiveValues {
                    logger.verbose("-----")
                    logger.verbose("\(objectiveType): \(objectiveParams)")
                    logger.verbose("-------------------")

                    // try to create qos test object from params
                    if let qosTest = QOSFactory.createQOSTest(objectiveType, params: objectiveParams) {

                        logger.debug("created qos test: \(qosTest)")

                        var concurrencyGroupArray: [QOSTest]? = qosTestConcurrencyGroupMap[qosTest.concurrencyGroup]
                        if concurrencyGroupArray == nil {
                            concurrencyGroupArray = [QOSTest]()
                        }

                        concurrencyGroupArray!.append(qosTest)
                        qosTestConcurrencyGroupMap[qosTest.concurrencyGroup] = concurrencyGroupArray // is this line needed? wasn't this passed by reference?

                        // increase test count
                        testCount += 1

                    } else {
                        logger.debug("unimplemented/unknown qos type: \(objectiveType)")
                    }
                }
            }
        }

        currentTestCount = testCount

        // create sorted array of keys to let the concurrencyGroups increase
        sortedConcurrencyGroups = Array(qosTestConcurrencyGroupMap.keys).sorted(by: <)

        logger.debug("sorted concurrency groups: \(self.sortedConcurrencyGroups)")
    }

    ///
    fileprivate func createTestTypeCountMap() {
        if stopped {
            return
        }

        var testTypeSortDictionary = [QOSMeasurementType: ConcurrencyGroup]()

        // fill testTypeCount map (used for displaying the finished test types in ui)
        for (cg, testArray) in qosTestConcurrencyGroupMap { // loop each concurrency group
            for test in testArray { // loop the tests inside each concurrency group
                let testType = test.getType()

                var count: UInt16? = testTypeCountMap[testType!]
                if count == nil {
                    count = 0
                }

                count! += 1

                testTypeCountMap[testType!] = count!

                //////

                if testTypeSortDictionary[testType!] == nil {
                    testTypeSortDictionary[testType!] = cg
                }
            }
        }

        // get test types and sort them according to their first execution
        var testTypeArray = [QOSMeasurementType](self.testTypeCountMap.keys)
        testTypeArray.sort() { lhs, rhs in
            testTypeSortDictionary[lhs] < testTypeSortDictionary[rhs]
        }

        // call didFetchTestTypes delegate method
        DispatchQueue.main.async {
            self.delegate?.qualityOfServiceTest(self, didFetchTestTypes: testTypeArray)
            return
        }

        logger.debug("TEST TYPE COUNT MAP: \(self.testTypeCountMap)")
    }

    ///
    fileprivate func runQOSTests() {
        logger.debug("RUN QOS TESTS (stopped: \(self.stopped))")

        if stopped {
            return
        }

        // start with first concurrency group
        runTestsOfNextConcurrencyGroup()
    }

    ///
    fileprivate func runTestsOfNextConcurrencyGroup() {
        if stopped {
            return
        }

        if sortedConcurrencyGroups.count > 0 {
            let concurrencyGroup = sortedConcurrencyGroups.remove(at: 0) // what happens if empty?

            logger.debug("run tests of next concurrency group: \(concurrencyGroup) (\(self.sortedConcurrencyGroups.count))")

            if let testArray = qosTestConcurrencyGroupMap[concurrencyGroup] {

                // set count of tests
                activeTestsInConcurrencyGroup = testArray.count

                // calculate control connection timeout (TODO: improve)
                // var controlConnectionTimeout: UInt64 = 0
                // for qosTest in testArray {
                //    controlConnectionTimeout += qosTest.timeout
                // }
                /////

                // loop test array
                for qosTest in testArray {
                    if stopped {
                        return
                    }

                    // get previously opened control connection
                    let controlConnection = getControlConnection(qosTest) // blocking if new connection has to be established

                    // get test executor
                    if let testExecutor = QOSFactory.createTestExecutor(qosTest, controlConnection: controlConnection, delegateQueue: executorQueue, speedtestStartTime: speedtestStartTime) {
                        // TODO: which queue?

                        // set test token (TODO: IMPROVE)
                        testExecutor.setCurrentTestToken(self.testToken)

                        if testExecutor.needsControlConnection() {
                            // set control connection timeout (TODO: compute better! (not all tests may use same control connection))
                            logger.debug("setting control connection timeout to \(nsToMs(qosTest.timeout)) ms")
                            controlConnection.setTimeout(qosTest.timeout)

                            // TODO: DETERMINE IF TEST NEEDS CONTROL CONNECTION
                            // IF IT NEEDS IT, AND CONTROL CONNECTION CONNECT FAILED THEN SKIP THIS TEST AND DON'T SEND RESULT TO SERVER
                            if !controlConnection.connected {
                                // don't do this test
                                logger.info("skipping test because it needs control connection but we don't have this connection. \(qosTest)")

                                self.mutualExclusionQueue.sync {
                                    self.qosTestFinishedWithResult(qosTest.getType(), withTestResult: nil) // no result because test didn't run
                                }

                                continue
                            }
                        }

                        logger.debug("starting execution of test: \(qosTest)")

                        // execute test
                        self.executorQueue.async {
                            testExecutor.execute { (testResult: QOSTestResult) in

                                self.mutualExclusionQueue.sync {
                                    self.qosTestFinishedWithResult(testResult.testType, withTestResult: testResult)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    ///
    fileprivate func qosTestFinishedWithResult(_ testType: QOSMeasurementType, withTestResult testResult: QOSTestResult?) {
        if stopped {
            return
        }

        logger.debug("qos test finished with result: \(testResult)")

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
        checkTestState()
    }

    ///
    fileprivate func checkProgress() {
        if stopped {
            return
        }

        // decrement test counts
        self.currentTestCount -= 1

        // check for progress
        let testsLeft = self.testCount - self.currentTestCount
        let percent: Float = Float(testsLeft) / Float(self.testCount)

        logger.debug("QOS: increasing progress to \(percent)")

        DispatchQueue.main.async {
            self.delegate?.qualityOfServiceTest(self, didProgressToValue: percent)
            return
        }
    }

    ///
    fileprivate func checkTypeCount(_ testType: QOSMeasurementType) {
        if stopped {
            return
        }

        // check for finished test type
        self.testTypeCountMap[testType]! -= 1
        if self.testTypeCountMap[testType]! == 0 {

            logger.debug("QOS: finished test type: \(testType)")

            DispatchQueue.main.async {
                self.delegate?.qualityOfServiceTest(self, didFinishTestType: testType)
                return
            }
        }
    }

    ///
    fileprivate func checkTestState() {
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
    fileprivate func finalizeQOSTests() {
        if stopped {
            return
        }

        logger.debug("ALL FINISHED")

        closeAllControlConnections()

        // submit results
        submitQOSTestResults()
    }

    ///
    fileprivate func getControlConnection(_ qosTest: QOSTest) -> QOSControlConnection {
        // determine control connection
        let controlConnectionKey: String = "\(qosTest.serverAddress)_\(qosTest.serverPort)"

        // TODO: make instantiation of control connection synchronous with locks!
        var conn: QOSControlConnection! = self.controlConnectionMap[controlConnectionKey]
        if conn == nil {
            logger.debug("\(controlConnectionKey): trying to open new control connection")
            // logger.debug("NO CONTROL CONNECTION PRESENT FOR \(controlConnectionKey), creating a new one")
            logger.debug("\(controlConnectionKey): BEFORE LOCK")

            // TODO: fail after timeout if qos server not available

            conn = QOSControlConnection(testToken: testToken)
            // conn.delegate = self

            // connect
            /* let isConnected = */_ = conn.connect(qosTest.serverAddress, onPort: qosTest.serverPort) // blocking

            // logger.debug("AFTER LOCK: have control connection?: \(isConnected)")
            // TODO: return nil? if not connected

            logger.debug("\(controlConnectionKey): AFTER LOCK -> CONTROL CONNECTION READY TO USE")

            controlConnectionMap[controlConnectionKey] = conn
        } else {
            logger.debug("\(controlConnectionKey): control connection already opened")
        }

        if !conn.connected {
            // reconnect
            _ = conn.connect(qosTest.serverAddress, onPort: qosTest.serverPort)
        }

        return conn
    }

    ///
    fileprivate func openAllControlConnections() {
        logger.info("opening all control connections")

        for concurrencyGroup in self.sortedConcurrencyGroups {
            if let testArray = qosTestConcurrencyGroupMap[concurrencyGroup] {
                for qosTest in testArray {
                    // dispatch_sync(mutualExclusionQueue) {
                        /* let controlConnection = */_ = self.getControlConnection(qosTest)
                        // logger.debug("opened control connection for qosTest \(qosTest)")
                    // }
                }
            }
        }
    }

    ///
    fileprivate func closeAllControlConnections() {
        logger.info("closing all control connections")

        // TODO: if everything is done: close all control connections
        for (_, controlConnection) in self.controlConnectionMap {
            logger.debug("closing control connection \(controlConnection)")
            controlConnection.disconnect()
        }
    }

    ///////////////

    ///
    fileprivate func fail(_ error: NSError?) {
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
    fileprivate func success() {
        if stopped {
            return
        }

        DispatchQueue.main.async {
            self.delegate?.qualityOfServiceTest(self, didFinishWithResults: self.resultArray)
            return
        }
    }

    ////////////////////////////////////////////

    ///
    fileprivate func submitQOSTestResults() {
        if stopped {
            return
        }

        var _testResultArray = [QOSTestResults]()

        for testResult in resultArray { // TODO: resultArray == _testResultArray? just use resultArray?
            if !testResult.isEmpty() {
                _testResultArray.append(testResult.resultDictionary)
            }
        }

        // don't send results if all results are empty (e.g. only tcp tests and no control connection)
        if _testResultArray.isEmpty {
            // inform delegate
            success()

            return
        }

        //

        let qosMeasurementResult = QosMeasurementResultRequest()
        qosMeasurementResult.measurementUuid = measurementUuid
        qosMeasurementResult.testToken = testToken
        qosMeasurementResult.time = NSNumber(value: currentTimeMillis() as UInt64).intValue // currently unused on server!
        qosMeasurementResult.qosResultList = _testResultArray

        let controlServer = ControlServer.sharedControlServer

        controlServer.submitQosMeasurementResult(qosMeasurementResult, success: { response in
            logger.debug("QOS TEST RESULT SUBMIT SUCCESS")

            // now the test has finished...succeeding methods should go here
            self.success()
        }) { error in
            logger.debug("QOS TEST RESULT SUBMIT ERROR: \(error)")

            // here the test failed...
            self.fail(error as NSError?)
        }
    }

}
