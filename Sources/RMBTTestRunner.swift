/*****************************************************************************************************
 * Copyright 2013 appscape gmbh
 * Copyright 2014-2016 SPECURE GmbH
 *
 * Licensed under the Apache Lvarnse, Version 2.0 (the "License");
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
import CoreLocation

#if os(iOS)
    import UIKit
#endif

///
public enum RMBTTestStatus: String {
    case None              = "NONE"
    case Aborted           = "ABORTED"
    case Error             = "ERROR"
    case ErrorFetching     = "ERROR_FETCH"
    case ErrorSubmitting   = "ERROR_SUBMIT"
    case ErrorBackgrounded = "ABORTED_BACKGROUNDED"
    case Ended             = "END"
}

///
let RMBTTestRunnerProgressUpdateInterval: TimeInterval = 0.1 // seconds

/*
// Used to assert that we are running on a correct queue via dispatch_queue_set_specific(),
// as dispatch_get_current_queue() is deprecated.
static void *const kWorkerQueueIdentityKey = (void *)&kWorkerQueueIdentityKey;
#define ASSERT_ON_WORKER_QUEUE() NSAssert(dispatch_get_specific(kWorkerQueueIdentityKey) != NULL, @"Running on a wrong queue")
*/

///
public enum RMBTTestRunnerPhase: Int {
    case none = 0
    case fetchingTestParams
    case wait
    case Init
    case latency
    case down
    case initUp
    case up
    case submittingTestResult
}

///
public enum RMBTTestRunnerCancelReason: Int {
    case userRequested
    case noConnection
    case mixedConnectivity
    case errorFetchingTestingParams
    case errorSubmittingTestResult
    case appBackgrounded
}

///
public protocol RMBTTestRunnerDelegate {

    ///
    func testRunnerDidStartPhase(_ phase: RMBTTestRunnerPhase)

    ///
    func testRunnerDidFinishPhase(_ phase: RMBTTestRunnerPhase)

    ///
    func testRunnerDidUpdateProgress(_ progress: Float, inPhase phase: RMBTTestRunnerPhase)

    ///
    func testRunnerDidMeasureThroughputs(_ throughputs: NSArray, inPhase phase: RMBTTestRunnerPhase)

    /// These delegate methods will be called even before the test starts
    func testRunnerDidDetectConnectivity(_ connectivity: RMBTConnectivity)

    ///
    func testRunnerDidDetectLocation(_ location: CLLocation)

    ///
    func testRunnerDidCompleteWithResult(_ uuid: String)

    ///
    func testRunnerDidCancelTestWithReason(_ cancelReason: RMBTTestRunnerCancelReason)

    ///
    func testRunnerDidFinishInit(_ time: UInt64)
}

///
open class RMBTTestRunner: NSObject, RMBTTestWorkerDelegate, RMBTConnectivityTrackerDelegate {

    ///
    fileprivate let workerQueue: DispatchQueue // We perform all work on this background queue. Workers also callback onto this queue.

    ///
    fileprivate var timer: DispatchSource!

    ///
    fileprivate var workers = [RMBTTestWorker]()

    ///
    fileprivate let delegate: RMBTTestRunnerDelegate

    ///
    fileprivate var phase: RMBTTestRunnerPhase = .none

    ///
    fileprivate var dead = false

    /// Flag indicating that downlink pretest in one of the workers was too slow and we need to
    /// continue with a single thread only
    fileprivate var singleThreaded = false

    ///
    open var testParams: SpeedMeasurementResponse!

    ///
    fileprivate let speedMeasurementResult = SpeedMeasurementResult(resolutionNanos: UInt64(RMBT_TEST_SAMPLING_RESOLUTION_MS) * NSEC_PER_MSEC) // TODO: remove public, maker better api

    ///
    fileprivate var connectivityTracker: RMBTConnectivityTracker!

    /// Snapshots of the network interface byte counts at a given phase
    fileprivate var startInterfaceInfo: RMBTConnectivityInterfaceInfo?
    fileprivate var uplinkStartInterfaceInfo: RMBTConnectivityInterfaceInfo?
    fileprivate var uplinkEndInterfaceInfo: RMBTConnectivityInterfaceInfo?
    fileprivate var downlinkStartInterfaceInfo: RMBTConnectivityInterfaceInfo?
    fileprivate var downlinkEndInterfaceInfo: RMBTConnectivityInterfaceInfo?

    ///
    fileprivate var finishedWorkers: UInt = 0
    fileprivate var activeWorkers: UInt = 0

    ///
    fileprivate var progressStartedAtNanos: UInt64 = 0
    fileprivate var progressDurationNanos: UInt64 = 0

    ///
    fileprivate var progressCompletionHandler: EmptyCallback!

    ///
    fileprivate var downlinkTestStartedAtNanos: UInt64 = 0
    fileprivate var uplinkTestStartedAtNanos: UInt64 = 0

    ///
    public init(delegate: RMBTTestRunnerDelegate) {
        self.delegate = delegate
        //self.phase = .None
        self.workerQueue = DispatchQueue(label: "at.rtr.rmbt.testrunner", attributes: []) // TODO: nil?

        super.init()

        /*
        void *nonNullValue = kWorkerQueueIdentityKey;
        dispatch_queue_set_specific(_workerQueue, kWorkerQueueIdentityKey, nonNullValue, NULL);
        */
        //dispatch_queue_set_specific(workerQueue, kWorkerQueueIdentityKey, nil, nil) // TODO!

        connectivityTracker = RMBTConnectivityTracker(delegate: self, stopOnMixed: true)
        connectivityTracker.start()
    }

    /// Run on main queue (called from VC)
    open func start() {
        assert(phase == .none, "Invalid state")
        assert(!dead, "Invalid state")

        phase = .fetchingTestParams

        ////////////////

        let speedMeasurementRequest = SpeedMeasurementRequest()

        speedMeasurementRequest.version = "0.3" // TODO: duplicate?
        speedMeasurementRequest.time = currentTimeMillis()

        speedMeasurementRequest.testCounter = RMBTSettings.sharedSettings.testCounter

        if let l = RMBTLocationTracker.sharedTracker.location {
            let geoLocation = GeoLocation(location: l)

            speedMeasurementRequest.geoLocation = geoLocation
        }

        let controlServer = ControlServer.sharedControlServer
        
        if RMBTConfig.sharedInstance.RMBT_VERSION_NEW {
            
            controlServer.requestSpeedMeasurement(speedMeasurementRequest, success: { response in
                self.workerQueue.async {
                    self.continueWithTestParams(response)
                }
            }) { error in
                self.workerQueue.async {
                    self.cancelWithReason(.errorFetchingTestingParams)
                }
            }
        } else {
        
            // workaround - nasty :(
            controlServer.requestSpeedMeasurement_Old(nil, success: { response in
                self.workerQueue.async {
                    
                    let r = SpeedMeasurementResponse()
                    r.clientRemoteIp = response.clientRemoteIp
                    r.duration = response.duration
                    r.pretestDuration = response.pretestDuration
                    r.measurementServer?.port = Int(response.port!)
                    r.measurementServer?.address = response.serverAddress
                    r.measurementServer?.name = response.serverName
                    r.numPings = Int(response.numPings)
                    r.numThreads = Int(response.numThreads)
                    r.testToken = response.testToken
                    r.testUuid = response.testUuid
                        
                    self.continueWithTestParams(r)
                }
            }) { error in
                self.workerQueue.async {
                    self.cancelWithReason(.errorFetchingTestingParams)
                }
            }
        }
        
        ////////////////

        // Notice that we post previous counter (the test before this one) when requesting the params
        RMBTSettings.sharedSettings.testCounter += 1
    }

    ///
    fileprivate func continueWithTestParams(_ testParams: SpeedMeasurementResponse/*RMBTTestParams*/) {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .fetchingTestParams || phase == .none, "Invalid state")

        if dead {
            return
        }

        self.testParams = testParams

        speedMeasurementResult.markTestStart()

        for i in 0..<testParams.numThreads {
            let worker = RMBTTestWorker(delegate: self, delegateQueue: workerQueue, index: UInt(i), testParams: testParams)
            workers.append(worker)
        }

        #if os(iOS)
            // Start observing app going to background notifications
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(RMBTTestRunner.applicationDidSwitchToBackground(_:)),
                name: NSNotification.Name.UIApplicationDidEnterBackground,
                object: nil
            )
        #endif

        // Register as observer for location tracker updates
        NotificationCenter.default.addObserver(self, selector: #selector(RMBTTestRunner.locationsDidChange(_:)), name: NSNotification.Name(rawValue: "RMBTLocationTrackerNotification"), object: nil)

        // ..and force an update right away
        RMBTLocationTracker.sharedTracker.forceUpdate()
        connectivityTracker.forceUpdate()

        let startInit = {
            self.startPhase(.Init, withAllWorkers: true, performingSelector: #selector(RMBTTestWorker.startDownlinkPretest), expectedDuration: testParams.pretestDuration, completion: nil)
        }

        if testParams.testWait > 0 {
            // Let progress timer run, then start init
            startPhase(.wait, withAllWorkers: false, performingSelector: nil, expectedDuration: testParams.testWait, completion: startInit)
        } else {
            startInit()
        }
    }


// MARK: Test worker delegate method

    ///
    open func testWorker(_ worker: RMBTTestWorker, didFinishDownlinkPretestWithChunkCount chunks: UInt, withTime duration: UInt64) {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .Init, "Invalid state")
        assert(!dead, "Invalid state")

        //should it be calculated init time recent time - start test time
        delegate.testRunnerDidFinishInit(duration)

        logger.debug("Thread \(worker.index): finished download pretest (chunks = \(chunks))")

        if !singleThreaded && chunks <= UInt(testParams.pretestMinChunkCountForMultithreading) {
            singleThreaded = true
        }

        if markWorkerAsFinished() {
            if singleThreaded {
                logger.debug("Downloaded <= \(self.testParams.pretestMinChunkCountForMultithreading) chunks in the pretest, continuing with single thread.")

                activeWorkers = UInt(testParams.numThreads) - 1
                finishedWorkers = 0

                for i in 1..<testParams.numThreads {
                    workers[Int(i)].stop()
                }

                speedMeasurementResult.startDownloadWithThreadCount(1)

            } else {
                speedMeasurementResult.startDownloadWithThreadCount(Int(testParams.numThreads))
                startPhase(.latency, withAllWorkers: false, performingSelector: #selector(RMBTTestWorker.startLatencyTest), expectedDuration: 0, completion: nil)
            }
        }
    }

    ///
    open func testWorkerDidStop(_ worker: RMBTTestWorker) {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .Init, "Invalid state")
        assert(!dead, "Invalid state")

        logger.debug("Thread \(worker.index): stopped")

        workers.remove(at: workers.index(of: worker)!) // !

        if markWorkerAsFinished() {
            // We stopped all but one workers because of slow connection. Proceed to latency with single worker.
            startPhase(.latency, withAllWorkers: false, performingSelector: #selector(RMBTTestWorker.startLatencyTest), expectedDuration: 0, completion: nil)
        }
    }

    ///
    open func testWorker(_ worker: RMBTTestWorker, didMeasureLatencyWithServerNanos serverNanos: UInt64, clientNanos: UInt64) {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .latency, "Invalid state")
        assert(!dead, "Invalid state")

        logger.debug("Thread \(worker.index): pong (server = \(serverNanos), client = \(clientNanos))")

        speedMeasurementResult.addPingWithServerNanos(serverNanos, clientNanos: clientNanos)

        let p = Double(speedMeasurementResult.pings.count) / Double(testParams.numPings)
        DispatchQueue.main.async {
            self.delegate.testRunnerDidUpdateProgress(Float(p), inPhase: self.phase)
        }
    }

    ///
    open func testWorkerDidFinishLatencyTest(_ worker: RMBTTestWorker) {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .latency, "Invalid state")
        assert(!dead, "Invalid state")

        if markWorkerAsFinished() {
            startPhase(.down, withAllWorkers: true, performingSelector: #selector(RMBTTestWorker.startDownlinkTest), expectedDuration: testParams.duration, completion: nil)
        }
    }

    ///
    open func testWorker(_ worker: RMBTTestWorker, didStartDownlinkTestAtNanos nanos: UInt64) -> UInt64 {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .down, "Invalid state")
        assert(!dead, "Invalid state")

        if downlinkTestStartedAtNanos == 0 {
            downlinkStartInterfaceInfo = speedMeasurementResult.lastConnectivity()?.getInterfaceInfo()
            downlinkTestStartedAtNanos = nanos
        }

        logger.debug("Thread \(worker.index): started downlink test with delay \(nanos - self.downlinkTestStartedAtNanos)")

        return downlinkTestStartedAtNanos
    }

    ///
    open func testWorker(_ worker: RMBTTestWorker, didDownloadLength length: UInt64, atNanos nanos: UInt64) {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .down, "Invalid state")
        assert(!dead, "Invalid state")

        let measuredThroughputs = speedMeasurementResult.addLength(length, atNanos: nanos, forThreadIndex: Int(worker.index))

        if measuredThroughputs != nil {
        //if let measuredThroughputs = testResult.addLength(length, atNanos: nanos, forThreadIndex: Int(worker.index)) {
            DispatchQueue.main.async {
                self.delegate.testRunnerDidMeasureThroughputs((measuredThroughputs as NSArray?)!, inPhase: .down)
            }
        }
    }

    ///
    open func testWorkerDidFinishDownlinkTest(_ worker: RMBTTestWorker) {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .down, "Invalid state")
        assert(!dead, "Invalid state")

        if markWorkerAsFinished() {
            logger.debug("Downlink test finished")

            downlinkEndInterfaceInfo = speedMeasurementResult.lastConnectivity()?.getInterfaceInfo()

            let measuredThroughputs = speedMeasurementResult.flush()

            speedMeasurementResult.totalDownloadHistory.log()

            if let _ = measuredThroughputs {
                DispatchQueue.main.async {
                    self.delegate.testRunnerDidMeasureThroughputs((measuredThroughputs as NSArray?)!, inPhase: .down)
                }
            }

            startPhase(.initUp, withAllWorkers: true, performingSelector: #selector(RMBTTestWorker.startUplinkPretest), expectedDuration: testParams.pretestDuration, completion: nil)
        }
    }

    ///
    open func testWorker(_ worker: RMBTTestWorker, didFinishUplinkPretestWithChunkCount chunks: UInt) {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .initUp, "Invalid state")
        assert(!dead, "Invalid state")

        logger.debug("Thread \(worker.index): finished uplink pretest (chunks = \(chunks))")

        if markWorkerAsFinished() {
            logger.debug("Uplink pretest finished")
            speedMeasurementResult.startUpload()
            startPhase(.up, withAllWorkers: true, performingSelector: #selector(RMBTTestWorker.startUplinkTest), expectedDuration: testParams.duration, completion: nil)
        }
    }

    ///
    open func testWorker(_ worker: RMBTTestWorker, didStartUplinkTestAtNanos nanos: UInt64) -> UInt64 {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .up, "Invalid state")
        assert(!dead, "Invalid state")

        var delay: UInt64 = 0

        if uplinkTestStartedAtNanos == 0 {
            uplinkTestStartedAtNanos = nanos
            delay = 0
            uplinkStartInterfaceInfo = speedMeasurementResult.lastConnectivity()?.getInterfaceInfo()
        } else {
            delay = nanos - uplinkTestStartedAtNanos
        }

        logger.debug("Thread \(worker.index): started uplink test with delay \(delay)")

        return delay
    }

    ///
    open func testWorker(_ worker: RMBTTestWorker, didUploadLength length: UInt64, atNanos nanos: UInt64) {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .up, "Invalid state")
        assert(!dead, "Invalid state")

        if let measuredThroughputs = speedMeasurementResult.addLength(length, atNanos: nanos, forThreadIndex: Int(worker.index)) {
            DispatchQueue.main.async {
                self.delegate.testRunnerDidMeasureThroughputs(measuredThroughputs as NSArray, inPhase: .up)
            }
        }
    }

    ///
    open func testWorkerDidFinishUplinkTest(_ worker: RMBTTestWorker) {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .up, "Invalid state")
        assert(!dead, "Invalid state")

        if markWorkerAsFinished() {
            // Stop observing now, test is finished

            finalize()

            uplinkEndInterfaceInfo = speedMeasurementResult.lastConnectivity()?.getInterfaceInfo()

            let measuredThroughputs = speedMeasurementResult.flush()
            logger.debug("Uplink test finished.")

            speedMeasurementResult.totalUploadHistory.log()

            if let _ = measuredThroughputs {
                DispatchQueue.main.async {
                    self.delegate.testRunnerDidMeasureThroughputs((measuredThroughputs as NSArray?)!, inPhase: .up)
                }
            }

            //self.phase = .SubmittingTestResult
            setPhase(.submittingTestResult)

            submitResult()
        }
    }

    ///
    open func testWorkerDidFail(_ worker: RMBTTestWorker) {
        //ASSERT_ON_WORKER_QUEUE();
        //assert(!dead, "Invalid state") // TODO: if worker fails, then this assertion lets app terminate

        self.cancelWithReason(.noConnection)
    }

///////

    ///
    fileprivate func submitResult() {
        workerQueue.async {
            if self.dead {
                return
            }

            self.setPhase(.submittingTestResult)

            let speedMeasurementResultRequest = self.resultObject()

            let controlServer = ControlServer.sharedControlServer

            controlServer.submitSpeedMeasurementResult(speedMeasurementResultRequest, success: { response in
                self.workerQueue.async {
                    self.setPhase(.none)
                    self.dead = true

                    RMBTSettings.sharedSettings.previousTestStatus = RMBTTestStatus.Ended.rawValue

                    if let uuid = self.testParams.testUuid {
                        DispatchQueue.main.async {
                            self.delegate.testRunnerDidCompleteWithResult(uuid)
                        }
                    } else {
                        self.workerQueue.async {
                            self.cancelWithReason(.errorSubmittingTestResult) // TODO
                        }
                    }
                }
            }, error: { error in
                self.workerQueue.async {
                    self.cancelWithReason(.errorSubmittingTestResult)
                }
            })
        }
    }

    ///
    fileprivate func resultObject() -> SpeedMeasurementResult {
        speedMeasurementResult.token = testParams.testToken
        speedMeasurementResult.uuid = testParams.testUuid

        //speedMeasurementResultRequest.portRemote =

        speedMeasurementResult.time = Date()

        // Collect total transfers from all threads
        var sumBytesDownloaded: UInt64 = 0
        var sumBytesUploaded: UInt64 = 0

        for w in workers {
            sumBytesDownloaded += w.totalBytesDownloaded
            sumBytesUploaded += w.totalBytesUploaded
        }

        assert(sumBytesDownloaded > 0, "Total bytes downloaded <= 0")
        assert(sumBytesUploaded > 0, "Total bytes uploaded <= 0")

        if let firstWorker = workers.first {
            speedMeasurementResult.totalBytesDownload = NSNumber(value: sumBytesDownloaded).intValue // TODO: ?
            speedMeasurementResult.totalBytesUpload = NSNumber(value: sumBytesUploaded).intValue // TODO: ?

            speedMeasurementResult.encryption = firstWorker.negotiatedEncryptionString

            speedMeasurementResult.ipLocal = firstWorker.localIp
            speedMeasurementResult.ipServer = firstWorker.serverIp
        }

        /////////////////////////// SOMETIMES SOME OF THESE VALUES ARE NOT SENT TO THE SERVER?

        //let interfaceUpDownTotal = interfaceBytesResultDictionaryWithStartInfo(startInterfaceInfo!, endInfo: uplinkEndInterfaceInfo!, prefix: "test")
        if let startInfo = startInterfaceInfo, let uplinkEndInfo = uplinkEndInterfaceInfo, startInfo.bytesReceived <= uplinkEndInfo.bytesReceived && startInfo.bytesSent < uplinkEndInfo.bytesSent {
            speedMeasurementResult.interfaceTotalBytesDownload = Int(uplinkEndInfo.bytesReceived - startInfo.bytesReceived)
            speedMeasurementResult.interfaceTotalBytesUpload = Int(uplinkEndInfo.bytesSent - startInfo.bytesSent)
        }

        //let interfaceUpDownDownload = interfaceBytesResultDictionaryWithStartInfo(downlinkStartInterfaceInfo!, endInfo: downlinkEndInterfaceInfo!, prefix: "testdl")
        if let downStartInfo = downlinkStartInterfaceInfo, let downEndInfo = downlinkEndInterfaceInfo, downStartInfo.bytesReceived <= downEndInfo.bytesReceived && downStartInfo.bytesSent < downEndInfo.bytesSent {
            speedMeasurementResult.interfaceDltestBytesDownload = Int(downEndInfo.bytesReceived - downStartInfo.bytesReceived)
            speedMeasurementResult.interfaceDltestBytesUpload = Int(downEndInfo.bytesSent - downStartInfo.bytesSent)
        }

        //let interfaceUpDownUpload = interfaceBytesResultDictionaryWithStartInfo(uplinkStartInterfaceInfo!, endInfo: uplinkEndInterfaceInfo!, prefix: "testul")
        if let upStartInfo = uplinkStartInterfaceInfo, let upEndInfo = uplinkEndInterfaceInfo, upStartInfo.bytesReceived <= upEndInfo.bytesReceived && upStartInfo.bytesSent < upEndInfo.bytesSent {
            speedMeasurementResult.interfaceUltestBytesDownload = Int(upEndInfo.bytesReceived - upStartInfo.bytesReceived)
            speedMeasurementResult.interfaceUltestBytesUpload = Int(upEndInfo.bytesSent - upStartInfo.bytesSent)
        }

        ///////////////////////////

        // Add relative time_(dl/ul)_ns timestamps
        let startNanos = speedMeasurementResult.testStartNanos

        speedMeasurementResult.relativeTimeDlNs = NSNumber(value: downlinkTestStartedAtNanos - startNanos).intValue
        speedMeasurementResult.relativeTimeUlNs = NSNumber(value: uplinkTestStartedAtNanos - startNanos).intValue

        //

        if TEST_USE_PERSONAL_DATA_FUZZING {
            speedMeasurementResult.publishPublicData = RMBTSettings.sharedSettings.publishPublicData
            logger.info("test result: publish_public_data: \(self.speedMeasurementResult.publishPublicData)")
        }

        //////

        speedMeasurementResult.calculate()

        return speedMeasurementResult
    }

// MARK: Utility methods

    ///
    fileprivate func setPhase(_ phase: RMBTTestRunnerPhase) {
        if self.phase != .none {
            let oldPhase = self.phase

            DispatchQueue.main.async {
                self.delegate.testRunnerDidFinishPhase(oldPhase)
            }
        }

        self.phase = phase

        if self.phase != .none {
            DispatchQueue.main.async {
                self.delegate.testRunnerDidStartPhase(self.phase)
            }
        }
    }

    ///
    fileprivate func startPhase(_ phase: RMBTTestRunnerPhase, withAllWorkers allWorkers: Bool, performingSelector selector: Selector!,
                            expectedDuration duration: TimeInterval, completion completionHandler: EmptyCallback!) {

        //ASSERT_ON_WORKER_QUEUE();

        //self.phase = phase
        setPhase(phase)

        finishedWorkers = 0
        progressStartedAtNanos = RMBTCurrentNanos()
        progressDurationNanos = UInt64(duration * Double(NSEC_PER_SEC))

        if timer != nil {
            timer.cancel()
            timer = nil
        }

        assert((completionHandler == nil) || duration > 0)

        if duration > 0 {
            progressCompletionHandler = completionHandler

            timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: 0), queue: DispatchQueue.global(qos: .default)) /*Migrator FIXME: Use DispatchSourceTimer to avoid the cast*/ as! DispatchSource
            // timer.setTimer(start: DispatchTime.now(), interval: UInt64(RMBTTestRunnerProgressUpdateInterval * Double(NSEC_PER_SEC)), leeway: 50 * NSEC_PER_MSEC)
            // ??????
            timer.scheduleRepeating(deadline: DispatchTime.now(), interval:RMBTTestRunnerProgressUpdateInterval * Double(NSEC_PER_SEC), leeway: DispatchTimeInterval.nanoseconds(50))
            timer.setEventHandler {
                let elapsedNanos = (RMBTCurrentNanos() - self.progressStartedAtNanos)
                if elapsedNanos > self.progressDurationNanos {
                    // We've reached end of interval...
                    // ..send 1.0 progress one last time..
                    DispatchQueue.main.async {
                        self.delegate.testRunnerDidUpdateProgress(1.0, inPhase: phase)
                    }

                    // ..then kill the timer
                    if self.timer != nil {
                        self.timer.cancel() // TODO: after swift rewrite of AppDelegate one test got an exception here!
                    }
                    self.timer = nil

                    // ..and perform completion handler, if any.
                    if self.progressCompletionHandler != nil {
                        self.workerQueue.async(execute: self.progressCompletionHandler)
                        self.progressCompletionHandler = nil
                    }
                } else {
                    let p = Double(elapsedNanos) / Double(self.progressDurationNanos)
                    assert(p <= 1.0, "Invalid percentage")

                    DispatchQueue.main.async {
                        self.delegate.testRunnerDidUpdateProgress(Float(p), inPhase: phase)
                    }
                }

            }
            timer.resume()
        }

        if selector == nil {
            return
        }

        if allWorkers {
            activeWorkers = UInt(workers.count)
            for w in workers {
                w.perform(selector)
            }
        } else {
            activeWorkers = 1
            _ = workers.first?.perform(selector)
        }
    }

    ///
    fileprivate func markWorkerAsFinished() -> Bool {
        finishedWorkers += 1
        return finishedWorkers == activeWorkers
    }

// MARK: Connectivity tracking

    ///
    open func connectivityTrackerDidDetectNoConnectivity(_ tracker: RMBTConnectivityTracker) {
        // Ignore for now, let connection time out
    }

    ///
    open func connectivityTracker(_ tracker: RMBTConnectivityTracker, didDetectConnectivity connectivity: RMBTConnectivity) {
        workerQueue.async {
            if self.speedMeasurementResult.lastConnectivity() == nil { // TODO: error here?
                self.startInterfaceInfo = connectivity.getInterfaceInfo()
            }

            if self.phase != .none {
                self.speedMeasurementResult.addConnectivity(connectivity)
            }
        }

        DispatchQueue.main.async {
            self.delegate.testRunnerDidDetectConnectivity(connectivity)
        }
    }

    ///
    open func connectivityTracker(_ tracker: RMBTConnectivityTracker, didStopAndDetectIncompatibleConnectivity connectivity: RMBTConnectivity) {
        DispatchQueue.main.async {
            self.delegate.testRunnerDidDetectConnectivity(connectivity)
        }

        workerQueue.async {
            if self.phase != .none {
                self.cancelWithReason(.mixedConnectivity)
            }
        }
    }

// MARK: App state tracking

    ///
    open func applicationDidSwitchToBackground(_ n: Notification) {
        logger.debug("App backgrounded, aborting \(n)")
        workerQueue.async {
            self.cancelWithReason(.appBackgrounded)
        }
    }

// MARK: Tracking location

    ///
    open func locationsDidChange(_ notification: Notification) {
        var lastLocation: CLLocation?

        for l in (notification.userInfo as! [String: AnyObject])["locations"] as! [CLLocation] { // !
            if CLLocationCoordinate2DIsValid(l.coordinate) {
                lastLocation = l
                speedMeasurementResult.addLocation(l)

                //NSLog(@"Location updated to (%f,%f,+/- %fm, %@)", l.coordinate.longitude, l.coordinate.latitude, l.horizontalAccuracy, l.timestamp);
                logger.debug("Location updated to (\(l.coordinate.longitude), \(l.coordinate.latitude), \(l.horizontalAccuracy), \(l.timestamp))")
            }
        }

        if let _ = lastLocation {
            DispatchQueue.main.async {
                self.delegate.testRunnerDidDetectLocation(lastLocation!) // !
            }
        }
    }

// MARK: Cancelling and cleanup

    ///
    override open func finalize() {
        // Stop observing
        connectivityTracker.stop()
        NotificationCenter.default.removeObserver(self)

        // Cancel timer
        if timer != nil {
            timer.cancel()
            timer = nil
        }
    }

    ///
    deinit {
        finalize()
    }

    ///
    fileprivate func cancelWithReason(_ reason: RMBTTestRunnerCancelReason) {
        //ASSERT_ON_WORKER_QUEUE();

        logger.debug("REASON: \(reason)")

        finalize()

        for w in workers {
            w.abort()
        }

        switch reason {
            case .userRequested: RMBTSettings.sharedSettings.previousTestStatus = RMBTTestStatus.Aborted.rawValue
            case .appBackgrounded: RMBTSettings.sharedSettings.previousTestStatus = RMBTTestStatus.ErrorBackgrounded.rawValue
            case .errorFetchingTestingParams: RMBTSettings.sharedSettings.previousTestStatus = RMBTTestStatus.ErrorFetching.rawValue
            case .errorSubmittingTestResult: RMBTSettings.sharedSettings.previousTestStatus = RMBTTestStatus.ErrorSubmitting.rawValue
        default: RMBTSettings.sharedSettings.previousTestStatus = RMBTTestStatus.Error.rawValue
        }

        phase = .none
        dead = true

        DispatchQueue.main.async {
            self.delegate.testRunnerDidCancelTestWithReason(reason)
        }
    }

    ///
    open func cancel() {
        workerQueue.async {
            self.cancelWithReason(.userRequested)
        }
    }

// MARK: Public API

    ///
    open func testStartNanos() -> UInt64 {
        return speedMeasurementResult.testStartNanos
    }

    ///
    open func medianPingNanos() -> UInt64 { // maybe better as computed property?
        return speedMeasurementResult.medianPingNanos
    }

    ///
    open func downloadKilobitsPerSecond() -> Int {
        return Int(speedMeasurementResult.totalDownloadHistory.totalThroughput.kilobitsPerSecond())
    }

    ///
    open func uploadKilobitsPerSecond() -> Int {
        return Int(speedMeasurementResult.totalUploadHistory.totalThroughput.kilobitsPerSecond())
    }

    ///
    open func addCpuUsage(_ cpuUsage: Double, atNanos ns: UInt64) {
        speedMeasurementResult.addCpuUsage(cpuUsage, atNanos: ns)
    }

    ///
    open func addMemoryUsage(_ ramUsage: Double, atNanos ns: UInt64) {
        speedMeasurementResult.addMemoryUsage(ramUsage, atNanos: ns)
    }

}
