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

    let RESULT_TEST_UID = "qos_test_uid"

    let RESULT_START_TIME = "start_time_ns"
    let RESULT_DURATION = "duration_ns"

    //

//    let TIMEOUT_EXTENSION: UInt64 = /*1*/1000 * NSEC_PER_MSEC // add 100ms to timeout because of compution etc.

    //

    ///
    let controlConnection: QOSControlConnection

    ///
    let delegateQueue: dispatch_queue_t

    ///
    let testObject: T

    ///
    let testResult: QOSTestResult

    ///
    var finishCallback: ((QOSTestResult) -> ())!

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
    init(controlConnection: QOSControlConnection, delegateQueue: dispatch_queue_t, testObject: T, speedtestStartTime: UInt64) {
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
        testResult = QOSTestResult(type: testType)

        // set initial values on test result
        testResult.set(RESULT_TEST_UID, value: self.testObject.qosTestId)

        //////
        qosLog = QOSLog(testType: testType, testUid: testObject.qosTestId)
        //////

        super.init()

        // set control connection task delegate if needed
        if needsControlConnection() {
            controlConnection.registerTaskDelegate(self, forTaskId: testObject.qosTestId)
        }

        // create timeout timer
        timer.interval = timeoutInSec
        timer.timerCallback = {
            self.qosLog.error("TIMEOUT IN QOS TEST")

            if !self.hasFinished {
                dispatch_async(self.delegateQueue) {
                    //assert(self.finishCallback != nil)
                    self.testDidTimeout()
                }
            }
        }
    }

    ///
    func setCurrentTestToken(testToken: String) {
        self.testToken = testToken
    }

    ///
    func startTimer() {
        timer.start()

        timeoutDuration = getCurrentTimeTicks()
    }

    ///
    func stopTimer() {
        timer.stop()

        if let _ = timeoutDuration {
            logger.info("stopped timeout timer after \((getTimeDifferenceInNanoSeconds(timeoutDuration)) / NSEC_PER_MSEC)ms")
        }
    }

    ///
    func startTest() {
        // set start time in nanoseconds minus start time of complete test
        testStartTimeTicks = getCurrentTimeTicks()

        testResult.set(RESULT_START_TIME, number: ticksToNanoTime(testStartTimeTicks) - speedtestStartTime) // test start time is relative to speedtest start time

        // start timeout timer
        if !needsCustomTimeoutHandling() {
            startTimer()
        }
    }

    ///
    func endTest() {
        // put duration
        let duration: UInt64 = getTimeDifferenceInNanoSeconds(testStartTimeTicks)
        testResult.set(RESULT_DURATION, number: duration)
    }

    ///
    func execute(finish finishCallback: (testResult: QOSTestResult) -> ()) {
        self.finishCallback = finishCallback

        // call startTest method
        self.startTest()

        // let subclasses execute the test
        self.executeTest()

//        if (!timeoutCountDownLatch.await(testObject.timeout)) {
//            // got timeout
//            logger.debug("QOS TEST TIMEOUT QOS TEST TIMEOUT QOS TEST TIMEOUT QOS TEST TIMEOUT QOS TEST TIMEOUT QOS TEST TIMEOUT QOS TEST TIMEOUT ")
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

        objc_sync_enter(self)

        // TODO: IMPROVE...let tests don't do anything if there are finished!

        // return if already finished
        if hasFinished {
            objc_sync_exit(self)
            return
        }
        hasFinished = true

        //let singleQueue = dispatch_queue_create("dwqdqw", DISPATCH_QUEUE_SERIAL)
        //dispatch_sync(singleQueue) {

            self.stopTimer()

            // call endTest method
            self.endTest()

            // freeze test result
            testResult.freeze()

            // unregister controlConnection delegate if needed
            if needsControlConnection() {
                logger.debug("\(self.controlConnection)")

                self.controlConnection.unregisterTaskDelegate(forTaskId: self.testObject.qosTestId)
            }

            // call finish callback saved in finishCallback variable
            qosLog.debug("calling finish callback")
            self.finishCallback(self.testResult) // TODO: run this in delegate queue?
        //}
        objc_sync_exit(self)
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
    func sendTaskCommand(command: String, withTimeout timeout: NSTimeInterval, tag: Int) {
        controlConnection.sendTaskCommand(command, withTimeout: timeout, forTaskId: testObject.qosTestId, tag: tag)
    }

    /// deprecated
    func failTestWithFatalError() {
        testResult.fatalError = true

        if !hasFinished {
            callFinishCallback()
        }
    }

// MARK: QOSControlConnectionTaskDelegate methods

    func controlConnection(connection: QOSControlConnection, didReceiveTaskResponse response: String, withTaskId taskId: UInt, tag: Int) {
        qosLog.debug("CONTROL CONNECTION DELEGATE FOR TASK ID \(taskId), WITH TAG \(tag), WITH STRING \(response)")
    }

    ///
    func controlConnection(connection: QOSControlConnection, didReceiveTimeout elapsed: NSTimeInterval, withTaskId taskId: UInt, tag: Int) {
        qosLog.debug("CONTROL CONNECTION DELEGATE FOR TASK ID \(taskId), WITH TAG \(tag), TIMEOUT")

        // let test timeout
        testDidTimeout()
    }
}

///
class QOSLog {

    ///
    let testType: QOSMeasurementType

    ///
    let testUid: UInt

    ///
    init(testType: QOSMeasurementType, testUid: UInt) {
        self.testType = testType
        self.testUid = testUid
    }

    ///
    func verbose(logMessage: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(logMessage, logLevel: .Verbose, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    ///
    func debug(logMessage: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(logMessage, logLevel: .Debug, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    ///
    func info(logMessage: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(logMessage, logLevel: .Info, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    ///
    func warning(logMessage: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(logMessage, logLevel: .Warning, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    ///
    func error(logMessage: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(logMessage, logLevel: .Error, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    ///
    func severe(logMessage: String, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        self.logln(logMessage, logLevel: .Severe, functionName: functionName, fileName: fileName, lineNumber: lineNumber)
    }

    ///
    func logln(logMessage: String, logLevel: XCGLogger.LogLevel = .Debug, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        if QOS_ENABLED_TESTS_LOG.contains(testType) {
            logger.logln(logMessage, logLevel: logLevel, functionName: "\(testType.rawValue.uppercaseString)<\(testUid)>: \(functionName)", fileName: fileName, lineNumber: lineNumber)
        }
    }
}
