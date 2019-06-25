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
import XCGLogger

///
class QOSTestExecutorClass<T: QOSTest>: NSObject, QOSTestExecutorProtocol, QOSControlConnectionTaskDelegate {

    func getTestObject() -> QOSTest {
        return self.testObject
    }
    
    let RESULT_TEST_UID = "qos_test_uid"

    let RESULT_START_TIME = "start_time_ns"
    let RESULT_DURATION = "duration_ns"

    //

//    let TIMEOUT_EXTENSION: UInt64 = /*1*/1000 * NSEC_PER_MSEC // add 100ms to timeout because of compution etc.

    //

    ///
    var controlConnection: QOSControlConnection?

    ///
    let delegateQueue: DispatchQueue

    ///
    let testObject: T

    ///
    let testResult: QOSTestResult

    ///
    var finishCallback: ((QOSTestResult) -> ())!
    var progressCallback: (_ executor: NSObject, _ percent: Float) -> Void = { _, _ in }

    ///
    var hasStarted: Bool = false

    ///
    var hasFinished: Bool = false

    ///
    var testStartTimeTicks: UInt64!

    ///
    let timeoutInSec: Double

    ///
    private let timer = GCDTimer()

    ///
    var testToken: String!

    ///
    let qosLog: QOSLog!

    ///
//    private let timeoutCountDownLatch: CountDownLatch = CountDownLatch()

    ///
    private var timeoutDuration: UInt64!

    ///
    private let speedtestStartTime: UInt64

    //

    ///
    init(controlConnection: QOSControlConnection?, delegateQueue: DispatchQueue, testObject: T, speedtestStartTime: UInt64) {
        self.controlConnection = controlConnection

        //self.delegate = delegate
        self.delegateQueue = delegateQueue

        self.testObject = testObject

        self.speedtestStartTime = speedtestStartTime

        //////
        self.timeoutInSec = nsToSec(testObject.timeout/* + TIMEOUT_EXTENSION*/)
        //////

        // initialize test result
        let testType = testObject.getType()
        testResult = QOSTestResult(type: testType!)

        // set initial values on test result
        testResult.set(RESULT_TEST_UID, value: self.testObject.qosTestId as AnyObject?)

        //////
        qosLog = QOSLog(testType: testType!, testUid: testObject.qosTestId)
        //////

        super.init()

        // set control connection task delegate if needed
        if needsControlConnection() {
            controlConnection?.registerTaskDelegate(self, forTaskId: testObject.qosTestId)
        }

        // create timeout timer
        timer.interval = timeoutInSec
        timer.timerCallback = { [weak self] in
            self?.qosLog.error("TIMEOUT IN QOS TEST")

            if self?.hasFinished == false {
                self?.delegateQueue.async {
                    //assert(self.finishCallback != nil)
                    self?.testDidTimeout()
                }
            }
        }
    }
    
    func testExecutorHasFinished() -> Bool {
        return self.hasFinished
    }

    func testObjectType() -> QosMeasurementType {
        return testObject.getType()
    }
    
    func setControlConnection(_ controlConnection: QOSControlConnection) {
        if needsControlConnection() {
            self.controlConnection = controlConnection
            self.controlConnection?.registerTaskDelegate(self, forTaskId: testObject.qosTestId)
        }
    }
    ///
    func setCurrentTestToken(_ testToken: String) {
        self.testToken = testToken
    }

    ///
    func startTimer() {
        timer.start()

        timeoutDuration = UInt64.getCurrentTimeTicks()
    }

    ///
    func stopTimer() {
        timer.stop()

        if let _ = timeoutDuration {
            Log.logger.info("stopped timeout timer after \((UInt64.getTimeDifferenceInNanoSeconds(self.timeoutDuration)) / NSEC_PER_MSEC)ms")
        }
    }

    ///
    func startTest() {
        // set start time in nanoseconds minus start time of complete test
        testStartTimeTicks = UInt64.getCurrentTimeTicks()

        testResult.set(RESULT_START_TIME, number: UInt64.ticksToNanoTime(testStartTimeTicks) - speedtestStartTime) // test start time is relative to speedtest start time

        // start timeout timer
        if !needsCustomTimeoutHandling() {
            startTimer()
        }
    }

    ///
    func endTest() {
        // put duration
        let duration: UInt64 = UInt64.getTimeDifferenceInNanoSeconds(testStartTimeTicks)
        testResult.set(RESULT_DURATION, number: duration)
    }
    
    func setProgressCallback(progressCallback: @escaping (_ executor: NSObject, _ percent: Float) -> Void) {
        self.progressCallback = progressCallback
    }

    ///
    func execute(finish finishCallback: @escaping (QOSTestResult) -> ()) {
        self.finishCallback = finishCallback

        // call startTest method
        self.startTest()

        // let subclasses execute the test
        self.executeTest()

//        if (!timeoutCountDownLatch.await(testObject.timeout)) {
//            // got timeout
//            Log.logger.debug("QOS TEST TIMEOUT QOS TEST TIMEOUT QOS TEST TIMEOUT QOS TEST TIMEOUT QOS TEST TIMEOUT QOS TEST TIMEOUT QOS TEST TIMEOUT ")
//            self.callFinishCallback()
//        }
    }

    ///
    func executeTest() {
        // do nothing, override this method in specialized classes
        assert(false, "func executeTest has to be overriden by sub classes!")
    }

    ///
    func callFinishCallback() {
//        timeoutCountDownLatch.countDown()

//        objc_sync_enter(self)

        // TODO: IMPROVE...let tests don't do anything if there are finished!

        // return if already finished
        if hasFinished {
//            objc_sync_exit(self)
            return
        }
        hasFinished = true

//        let serialQueue = DispatchQueue(label: "test-executor-queue")
//        serialQueue.sync {
        
            
            self.stopTimer()

            // call endTest method
            self.endTest()

            // freeze test result
            testResult.freeze()

            // unregister controlConnection delegate if needed
            if needsControlConnection() {
                Log.logger.debug("\(String(describing: self.controlConnection))")

                self.controlConnection?.unregisterTaskDelegate(self, forTaskId: self.testObject.qosTestId)
            }

            // call finish callback saved in finishCallback variable
            qosLog.debug("calling finish callback")
            self.finishCallback(self.testResult) // TODO: run this in delegate queue?
//        }
//        objc_sync_exit(self)
    }

    ///
    func testDidSucceed() {
        // TODO: override in specific tests

        if !hasFinished {
            callFinishCallback()
        }
    }

    ///
    func testDidTimeout() {
        // TODO: override in specific tests

        if !hasFinished {
            callFinishCallback()
        }
    }

    ///
    func testDidFail() {
        // TODO: override in specific tests

        if !hasFinished {
            callFinishCallback()
        }
    }

    ///
    func needsControlConnection() -> Bool {
        return true
    }

    ///
    func needsCustomTimeoutHandling() -> Bool {
        return false
    }

    ////////////

// MARK: convenience methods

    ///
    func sendTaskCommand(_ command: String, withTimeout timeout: TimeInterval, tag: Int) {
        controlConnection?.sendTaskCommand(command, withTimeout: timeout, forTaskId: testObject.qosTestId, tag: tag)
    }

    /// deprecated
    func failTestWithFatalError() {
        testResult.fatalError = true

        if !hasFinished {
            callFinishCallback()
        }
    }

// MARK: QOSControlConnectionTaskDelegate methods

    func controlConnection(_ connection: QOSControlConnection, didReceiveTaskResponse response: String, withTaskId taskId: UInt, tag: Int) {
        qosLog.debug("CONTROL CONNECTION DELEGATE FOR TASK ID \(taskId), WITH TAG \(tag), WITH STRING \(response)")
    }

    ///
    func controlConnection(_ connection: QOSControlConnection, didReceiveTimeout elapsed: TimeInterval, withTaskId taskId: UInt, tag: Int) {
        qosLog.debug("CONTROL CONNECTION DELEGATE FOR TASK ID \(taskId), WITH TAG \(tag), TIMEOUT")

        // let test timeout
        testDidTimeout()
    }

}

///
class QOSLog {

    ///
    let testType: QosMeasurementType

    ///
    let testUid: UInt

    ///
    init(testType: QosMeasurementType, testUid: UInt) {
        self.testType = testType
        self.testUid = testUid
    }

    ///
    func verbose(_ logMessage: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(logMessage, logLevel: .verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    ///
    func debug(_ logMessage: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(logMessage, logLevel: .debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    ///
    func info(_ logMessage: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(logMessage, logLevel: .info, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    ///
    func warning(_ logMessage: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(logMessage, logLevel: .warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    ///
    func error(_ logMessage: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(logMessage, logLevel: .error, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    ///
    func severe(_ logMessage: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(logMessage, logLevel: .severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    ///
    private func logln(_ logMessage: String, logLevel: XCGLogger.Level = .debug, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
//        let s = "\(testType.rawValue.uppercased())<\(testUid)>: \(functionName)"
//        
//        let sString:StaticString = s
        
        if QOS_ENABLED_TESTS_LOG.contains(testType) {
            // Log.logger.logln(logMessage, level: logLevel, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
        }
    }
}
