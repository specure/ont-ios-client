/*****************************************************************************************************
 * Copyright 2013 appscape gmbh
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
let RMBTTestRunnerProgressUpdateInterval: NSTimeInterval = 0.1 // seconds

/*
// Used to assert that we are running on a correct queue via dispatch_queue_set_specific(),
// as dispatch_get_current_queue() is deprecated.
static void *const kWorkerQueueIdentityKey = (void *)&kWorkerQueueIdentityKey;
#define ASSERT_ON_WORKER_QUEUE() NSAssert(dispatch_get_specific(kWorkerQueueIdentityKey) != NULL, @"Running on a wrong queue")
*/

///
public enum RMBTTestRunnerPhase: Int {
    case None = 0
    case FetchingTestParams
    case Wait
    case Init
    case Latency
    case Down
    case InitUp
    case Up
    case SubmittingTestResult
}

///
public enum RMBTTestRunnerCancelReason: Int {
    case UserRequested
    case NoConnection
    case MixedConnectivity
    case ErrorFetchingTestingParams
    case ErrorSubmittingTestResult
    case AppBackgrounded
}

///
public protocol RMBTTestRunnerDelegate {

    ///
    func testRunnerDidStartPhase(phase: RMBTTestRunnerPhase)

    ///
    func testRunnerDidFinishPhase(phase: RMBTTestRunnerPhase)

    ///
    func testRunnerDidUpdateProgress(progress: Float, inPhase phase: RMBTTestRunnerPhase)

    ///
    func testRunnerDidMeasureThroughputs(throughputs: NSArray, inPhase phase: RMBTTestRunnerPhase)

    /// These delegate methods will be called even before the test starts
    func testRunnerDidDetectConnectivity(connectivity: RMBTConnectivity)

    ///
    func testRunnerDidDetectLocation(location: CLLocation)

    ///
    func testRunnerDidCompleteWithResult(uuid: String)

    ///
    func testRunnerDidCancelTestWithReason(cancelReason: RMBTTestRunnerCancelReason)

    ///
    func testRunnerDidFinishInit(time: UInt64)
}

///
public class RMBTTestRunner: NSObject, RMBTTestWorkerDelegate, RMBTConnectivityTrackerDelegate {

    ///
    private let workerQueue: dispatch_queue_t // We perform all work on this background queue. Workers also callback onto this queue.

    ///
    private var timer: dispatch_source_t!

    ///
    private var workers = [RMBTTestWorker]()

    ///
    private let delegate: RMBTTestRunnerDelegate

    ///
    private var phase: RMBTTestRunnerPhase = .None

    ///
    private var dead = false

    /// Flag indicating that downlink pretest in one of the workers was too slow and we need to
    /// continue with a single thread only
    private var singleThreaded = false

    ///
    public var testParams: SpeedMeasurementResponse!

    ///
    private let speedMeasurementResult = SpeedMeasurementResult(resolutionNanos: UInt64(RMBT_TEST_SAMPLING_RESOLUTION_MS) * NSEC_PER_MSEC) // TODO: remove public, maker better api

    ///
    private var connectivityTracker: RMBTConnectivityTracker!

    /// Snapshots of the network interface byte counts at a given phase
    private var startInterfaceInfo: RMBTConnectivityInterfaceInfo?
    private var uplinkStartInterfaceInfo: RMBTConnectivityInterfaceInfo?
    private var uplinkEndInterfaceInfo: RMBTConnectivityInterfaceInfo?
    private var downlinkStartInterfaceInfo: RMBTConnectivityInterfaceInfo?
    private var downlinkEndInterfaceInfo: RMBTConnectivityInterfaceInfo?

    ///
    private var finishedWorkers: UInt = 0
    private var activeWorkers: UInt = 0

    ///
    private var progressStartedAtNanos: UInt64 = 0
    private var progressDurationNanos: UInt64 = 0

    ///
    private var progressCompletionHandler: EmptyCallback!

    ///
    private var downlinkTestStartedAtNanos: UInt64 = 0
    private var uplinkTestStartedAtNanos: UInt64 = 0

    ///
    public init(delegate: RMBTTestRunnerDelegate) {
        self.delegate = delegate
        //self.phase = .None
        self.workerQueue = dispatch_queue_create("at.rtr.rmbt.testrunner", nil) // TODO: nil?

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
    public func start() {
        assert(phase == .None, "Invalid state")
        assert(!dead, "Invalid state")

        phase = .FetchingTestParams

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
        controlServer.requestSpeedMeasurement(speedMeasurementRequest, success: { response in
            dispatch_async(self.workerQueue) {
                self.continueWithTestParams(response)
            }
        }) { error in
            dispatch_async(self.workerQueue) {
                self.cancelWithReason(.ErrorFetchingTestingParams)
            }
        }

        ////////////////

        // Notice that we post previous counter (the test before this one) when requesting the params
        RMBTSettings.sharedSettings.testCounter += 1
    }

    ///
    private func continueWithTestParams(testParams: SpeedMeasurementResponse/*RMBTTestParams*/) {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .FetchingTestParams || phase == .None, "Invalid state")

        if dead {
            return
        }

        self.testParams = testParams

        speedMeasurementResult.markTestStart()

        for i in 0..<(testParams.numThreads ?? 0) {
            let worker = RMBTTestWorker(delegate: self, delegateQueue: workerQueue, index: UInt(i), testParams: testParams)
            workers.append(worker)
        }

        #if os(iOS)
            // Start observing app going to background notifications
            NSNotificationCenter.defaultCenter().addObserver(
                self,
                selector: #selector(RMBTTestRunner.applicationDidSwitchToBackground(_:)),
                name: UIApplicationDidEnterBackgroundNotification,
                object: nil
            )
        #endif

        // Register as observer for location tracker updates
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(RMBTTestRunner.locationsDidChange(_:)), name: "RMBTLocationTrackerNotification", object: nil)

        // ..and force an update right away
        RMBTLocationTracker.sharedTracker.forceUpdate()
        connectivityTracker.forceUpdate()

        let startInit = {
            self.startPhase(.Init, withAllWorkers: true, performingSelector: #selector(RMBTTestWorker.startDownlinkPretest), expectedDuration: testParams.pretestDuration, completion: nil)
        }

        if testParams.testWait > 0 {
            // Let progress timer run, then start init
            startPhase(.Wait, withAllWorkers: false, performingSelector: nil, expectedDuration: testParams.testWait, completion: startInit)
        } else {
            startInit()
        }
    }


// MARK: Test worker delegate method

    ///
    public func testWorker(worker: RMBTTestWorker, didFinishDownlinkPretestWithChunkCount chunks: UInt, withTime duration: UInt64) {
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
                startPhase(.Latency, withAllWorkers: false, performingSelector: #selector(RMBTTestWorker.startLatencyTest), expectedDuration: 0, completion: nil)
            }
        }
    }

    ///
    public func testWorkerDidStop(worker: RMBTTestWorker) {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .Init, "Invalid state")
        assert(!dead, "Invalid state")

        logger.debug("Thread \(worker.index): stopped")

        workers.removeAtIndex(workers.indexOf(worker)!) // !

        if markWorkerAsFinished() {
            // We stopped all but one workers because of slow connection. Proceed to latency with single worker.
            startPhase(.Latency, withAllWorkers: false, performingSelector: #selector(RMBTTestWorker.startLatencyTest), expectedDuration: 0, completion: nil)
        }
    }

    ///
    public func testWorker(worker: RMBTTestWorker, didMeasureLatencyWithServerNanos serverNanos: UInt64, clientNanos: UInt64) {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .Latency, "Invalid state")
        assert(!dead, "Invalid state")

        logger.debug("Thread \(worker.index): pong (server = \(serverNanos), client = \(clientNanos))")

        speedMeasurementResult.addPingWithServerNanos(serverNanos, clientNanos: clientNanos)

        let p = Double(speedMeasurementResult.pings.count) / Double(testParams.numPings)
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate.testRunnerDidUpdateProgress(Float(p), inPhase: self.phase)
        }
    }

    ///
    public func testWorkerDidFinishLatencyTest(worker: RMBTTestWorker) {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .Latency, "Invalid state")
        assert(!dead, "Invalid state")

        if markWorkerAsFinished() {
            startPhase(.Down, withAllWorkers: true, performingSelector: #selector(RMBTTestWorker.startDownlinkTest), expectedDuration: testParams.duration, completion: nil)
        }
    }

    ///
    public func testWorker(worker: RMBTTestWorker, didStartDownlinkTestAtNanos nanos: UInt64) -> UInt64 {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .Down, "Invalid state")
        assert(!dead, "Invalid state")

        if downlinkTestStartedAtNanos == 0 {
            downlinkStartInterfaceInfo = speedMeasurementResult.lastConnectivity()?.getInterfaceInfo()
            downlinkTestStartedAtNanos = nanos
        }

        logger.debug("Thread \(worker.index): started downlink test with delay \(nanos - self.downlinkTestStartedAtNanos)")

        return downlinkTestStartedAtNanos
    }

    ///
    public func testWorker(worker: RMBTTestWorker, didDownloadLength length: UInt64, atNanos nanos: UInt64) {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .Down, "Invalid state")
        assert(!dead, "Invalid state")

        let measuredThroughputs = speedMeasurementResult.addLength(length, atNanos: nanos, forThreadIndex: Int(worker.index))

        if measuredThroughputs != nil {
        //if let measuredThroughputs = testResult.addLength(length, atNanos: nanos, forThreadIndex: Int(worker.index)) {
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate.testRunnerDidMeasureThroughputs(measuredThroughputs, inPhase: .Down)
            }
        }
    }

    ///
    public func testWorkerDidFinishDownlinkTest(worker: RMBTTestWorker) {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .Down, "Invalid state")
        assert(!dead, "Invalid state")

        if markWorkerAsFinished() {
            logger.debug("Downlink test finished")

            downlinkEndInterfaceInfo = speedMeasurementResult.lastConnectivity()?.getInterfaceInfo()

            let measuredThroughputs = speedMeasurementResult.flush()

            speedMeasurementResult.totalDownloadHistory.log()

            if let _ = measuredThroughputs {
                dispatch_async(dispatch_get_main_queue()) {
                    self.delegate.testRunnerDidMeasureThroughputs(measuredThroughputs, inPhase: .Down)
                }
            }

            startPhase(.InitUp, withAllWorkers: true, performingSelector: #selector(RMBTTestWorker.startUplinkPretest), expectedDuration: testParams.pretestDuration, completion: nil)
        }
    }

    ///
    public func testWorker(worker: RMBTTestWorker, didFinishUplinkPretestWithChunkCount chunks: UInt) {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .InitUp, "Invalid state")
        assert(!dead, "Invalid state")

        logger.debug("Thread \(worker.index): finished uplink pretest (chunks = \(chunks))")

        if markWorkerAsFinished() {
            logger.debug("Uplink pretest finished")
            speedMeasurementResult.startUpload()
            startPhase(.Up, withAllWorkers: true, performingSelector: #selector(RMBTTestWorker.startUplinkTest), expectedDuration: testParams.duration, completion: nil)
        }
    }

    ///
    public func testWorker(worker: RMBTTestWorker, didStartUplinkTestAtNanos nanos: UInt64) -> UInt64 {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .Up, "Invalid state")
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
    public func testWorker(worker: RMBTTestWorker, didUploadLength length: UInt64, atNanos nanos: UInt64) {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .Up, "Invalid state")
        assert(!dead, "Invalid state")

        if let measuredThroughputs = speedMeasurementResult.addLength(length, atNanos: nanos, forThreadIndex: Int(worker.index)) {
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate.testRunnerDidMeasureThroughputs(measuredThroughputs, inPhase: .Up)
            }
        }
    }

    ///
    public func testWorkerDidFinishUplinkTest(worker: RMBTTestWorker) {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .Up, "Invalid state")
        assert(!dead, "Invalid state")

        if markWorkerAsFinished() {
            // Stop observing now, test is finished

            finalize()

            uplinkEndInterfaceInfo = speedMeasurementResult.lastConnectivity()?.getInterfaceInfo()

            let measuredThroughputs = speedMeasurementResult.flush()
            logger.debug("Uplink test finished.")

            speedMeasurementResult.totalUploadHistory.log()

            if let _ = measuredThroughputs {
                dispatch_async(dispatch_get_main_queue()) {
                    self.delegate.testRunnerDidMeasureThroughputs(measuredThroughputs, inPhase: .Up)
                }
            }

            //self.phase = .SubmittingTestResult
            setPhase(.SubmittingTestResult)

            submitResult()
        }
    }

    ///
    public func testWorkerDidFail(worker: RMBTTestWorker) {
        //ASSERT_ON_WORKER_QUEUE();
        //assert(!dead, "Invalid state") // TODO: if worker fails, then this assertion lets app terminate

        self.cancelWithReason(.NoConnection)
    }

///////

    ///
    private func submitResult() {
        dispatch_async(workerQueue) {
            if self.dead {
                return
            }

            self.setPhase(.SubmittingTestResult)

            let speedMeasurementResultRequest = self.resultObject()

            let controlServer = ControlServer.sharedControlServer

            controlServer.submitSpeedMeasurementResult(speedMeasurementResultRequest, success: { response in
                dispatch_async(self.workerQueue) {
                    //self.phase = .None
                    self.setPhase(.None)
                    self.dead = true

                    RMBTSettings.sharedSettings.previousTestStatus = RMBTTestStatus.Ended.rawValue

                    if let uuid = self.testParams.testUuid {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.delegate.testRunnerDidCompleteWithResult(uuid)
                        }
                    } else {
                        dispatch_async(self.workerQueue) {
                            self.cancelWithReason(.ErrorSubmittingTestResult) // TODO
                        }
                    }
                }
            }, error: { error in
                dispatch_async(self.workerQueue) {
                    self.cancelWithReason(.ErrorSubmittingTestResult)
                }
            })
        }
    }

    ///
    private func resultObject() -> SpeedMeasurementResult {
        speedMeasurementResult.token = testParams.testToken
        speedMeasurementResult.uuid = testParams.testUuid

        //speedMeasurementResultRequest.portRemote =

        speedMeasurementResult.time = NSDate()

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
            speedMeasurementResult.totalBytesDownload = NSNumber(unsignedLongLong: sumBytesDownloaded).integerValue // TODO: ?
            speedMeasurementResult.totalBytesUpload = NSNumber(unsignedLongLong: sumBytesUploaded).integerValue // TODO: ?

            speedMeasurementResult.encryption = firstWorker.negotiatedEncryptionString

            speedMeasurementResult.ipLocal = firstWorker.localIp
            speedMeasurementResult.ipServer = firstWorker.serverIp
        }

        /////////////////////////// SOMETIMES SOME OF THESE VALUES ARE NOT SENT TO THE SERVER?

        //let interfaceUpDownTotal = interfaceBytesResultDictionaryWithStartInfo(startInterfaceInfo!, endInfo: uplinkEndInterfaceInfo!, prefix: "test")
        if let startInfo = startInterfaceInfo, uplinkEndInfo = uplinkEndInterfaceInfo where startInfo.bytesReceived <= uplinkEndInfo.bytesReceived && startInfo.bytesSent < uplinkEndInfo.bytesSent {
            speedMeasurementResult.interfaceTotalBytesDownload = Int(uplinkEndInfo.bytesReceived - startInfo.bytesReceived)
            speedMeasurementResult.interfaceTotalBytesUpload = Int(uplinkEndInfo.bytesSent - startInfo.bytesSent)
        }

        //let interfaceUpDownDownload = interfaceBytesResultDictionaryWithStartInfo(downlinkStartInterfaceInfo!, endInfo: downlinkEndInterfaceInfo!, prefix: "testdl")
        if let downStartInfo = downlinkStartInterfaceInfo, downEndInfo = downlinkEndInterfaceInfo where downStartInfo.bytesReceived <= downEndInfo.bytesReceived && downStartInfo.bytesSent < downEndInfo.bytesSent {
            speedMeasurementResult.interfaceDltestBytesDownload = Int(downEndInfo.bytesReceived - downStartInfo.bytesReceived)
            speedMeasurementResult.interfaceDltestBytesUpload = Int(downEndInfo.bytesSent - downStartInfo.bytesSent)
        }

        //let interfaceUpDownUpload = interfaceBytesResultDictionaryWithStartInfo(uplinkStartInterfaceInfo!, endInfo: uplinkEndInterfaceInfo!, prefix: "testul")
        if let upStartInfo = uplinkStartInterfaceInfo, upEndInfo = uplinkEndInterfaceInfo where upStartInfo.bytesReceived <= upEndInfo.bytesReceived && upStartInfo.bytesSent < upEndInfo.bytesSent {
            speedMeasurementResult.interfaceUltestBytesDownload = Int(upEndInfo.bytesReceived - upStartInfo.bytesReceived)
            speedMeasurementResult.interfaceUltestBytesUpload = Int(upEndInfo.bytesSent - upStartInfo.bytesSent)
        }

        ///////////////////////////

        // Add relative time_(dl/ul)_ns timestamps
        let startNanos = speedMeasurementResult.testStartNanos

        speedMeasurementResult.relativeTimeDlNs = NSNumber(unsignedLongLong: downlinkTestStartedAtNanos - startNanos).integerValue
        speedMeasurementResult.relativeTimeUlNs = NSNumber(unsignedLongLong: uplinkTestStartedAtNanos - startNanos).integerValue

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
    private func setPhase(phase: RMBTTestRunnerPhase) {
        if self.phase != .None {
            let oldPhase = self.phase

            dispatch_async(dispatch_get_main_queue()) {
                self.delegate.testRunnerDidFinishPhase(oldPhase)
            }
        }

        self.phase = phase

        if self.phase != .None {
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate.testRunnerDidStartPhase(self.phase)
            }
        }
    }

    ///
    private func startPhase(phase: RMBTTestRunnerPhase, withAllWorkers allWorkers: Bool, performingSelector selector: Selector!,
                            expectedDuration duration: NSTimeInterval, completion completionHandler: EmptyCallback!) {

        //ASSERT_ON_WORKER_QUEUE();

        //self.phase = phase
        setPhase(phase)

        finishedWorkers = 0
        progressStartedAtNanos = RMBTCurrentNanos()
        progressDurationNanos = UInt64(duration * Double(NSEC_PER_SEC))

        if timer != nil {
            dispatch_source_cancel(timer)
            timer = nil
        }

        assert((completionHandler == nil) || duration > 0)

        if duration > 0 {
            progressCompletionHandler = completionHandler

            timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))
            dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, UInt64(RMBTTestRunnerProgressUpdateInterval * Double(NSEC_PER_SEC)), 50 * NSEC_PER_MSEC)
            dispatch_source_set_event_handler(timer) {
                let elapsedNanos = (RMBTCurrentNanos() - self.progressStartedAtNanos)
                if elapsedNanos > self.progressDurationNanos {
                    // We've reached end of interval...
                    // ..send 1.0 progress one last time..
                    dispatch_async(dispatch_get_main_queue()) {
                        self.delegate.testRunnerDidUpdateProgress(1.0, inPhase: phase)
                    }

                    // ..then kill the timer
                    if self.timer != nil {
                        dispatch_source_cancel(self.timer) // TODO: after swift rewrite of AppDelegate one test got an exception here!
                    }
                    self.timer = nil

                    // ..and perform completion handler, if any.
                    if self.progressCompletionHandler != nil {
                        dispatch_async(self.workerQueue, self.progressCompletionHandler)
                        self.progressCompletionHandler = nil
                    }
                } else {
                    let p = Double(elapsedNanos) / Double(self.progressDurationNanos)
                    assert(p <= 1.0, "Invalid percentage")

                    dispatch_async(dispatch_get_main_queue()) {
                        self.delegate.testRunnerDidUpdateProgress(Float(p), inPhase: phase)
                    }
                }

            }
            dispatch_resume(timer)
        }

        if selector == nil {
            return
        }

        if allWorkers {
            activeWorkers = UInt(workers.count)
            for w in workers {
                w.performSelector(selector)
            }
        } else {
            activeWorkers = 1
            workers.first?.performSelector(selector)
        }
    }

    ///
    private func markWorkerAsFinished() -> Bool {
        finishedWorkers += 1
        return finishedWorkers == activeWorkers
    }

// MARK: Connectivity tracking

    ///
    public func connectivityTrackerDidDetectNoConnectivity(tracker: RMBTConnectivityTracker) {
        // Ignore for now, let connection time out
    }

    ///
    public func connectivityTracker(tracker: RMBTConnectivityTracker, didDetectConnectivity connectivity: RMBTConnectivity) {
        dispatch_async(workerQueue) {
            if self.speedMeasurementResult.lastConnectivity() == nil { // TODO: error here?
                self.startInterfaceInfo = connectivity.getInterfaceInfo()
            }

            if self.phase != .None {
                self.speedMeasurementResult.addConnectivity(connectivity)
            }
        }

        dispatch_async(dispatch_get_main_queue()) {
            self.delegate.testRunnerDidDetectConnectivity(connectivity)
        }
    }

    ///
    public func connectivityTracker(tracker: RMBTConnectivityTracker, didStopAndDetectIncompatibleConnectivity connectivity: RMBTConnectivity) {
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate.testRunnerDidDetectConnectivity(connectivity)
        }

        dispatch_async(workerQueue) {
            if self.phase != .None {
                self.cancelWithReason(.MixedConnectivity)
            }
        }
    }

// MARK: App state tracking

    ///
    public func applicationDidSwitchToBackground(n: NSNotification) {
        logger.debug("App backgrounded, aborting \(n)")
        dispatch_async(workerQueue) {
            self.cancelWithReason(.AppBackgrounded)
        }
    }

// MARK: Tracking location

    ///
    public func locationsDidChange(notification: NSNotification) {
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
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate.testRunnerDidDetectLocation(lastLocation!) // !
            }
        }
    }

// MARK: Cancelling and cleanup

    ///
    override public func finalize() {
        // Stop observing
        connectivityTracker.stop()
        NSNotificationCenter.defaultCenter().removeObserver(self)

        // Cancel timer
        if timer != nil {
            dispatch_source_cancel(timer)
            timer = nil
        }
    }

    ///
    deinit {
        finalize()
    }

    ///
    private func cancelWithReason(reason: RMBTTestRunnerCancelReason) {
        //ASSERT_ON_WORKER_QUEUE();

        logger.debug("REASON: \(reason)")

        finalize()

        for w in workers {
            w.abort()
        }

        switch reason {
        case .UserRequested:
            RMBTSettings.sharedSettings.previousTestStatus = RMBTTestStatus.Aborted.rawValue
        case .AppBackgrounded:
            RMBTSettings.sharedSettings.previousTestStatus = RMBTTestStatus.ErrorBackgrounded.rawValue
        case .ErrorFetchingTestingParams:
            RMBTSettings.sharedSettings.previousTestStatus = RMBTTestStatus.ErrorFetching.rawValue
        case .ErrorSubmittingTestResult:
            RMBTSettings.sharedSettings.previousTestStatus = RMBTTestStatus.ErrorSubmitting.rawValue
        default:
            RMBTSettings.sharedSettings.previousTestStatus = RMBTTestStatus.Error.rawValue
        }

        phase = .None
        dead = true

        dispatch_async(dispatch_get_main_queue()) {
            self.delegate.testRunnerDidCancelTestWithReason(reason)
        }
    }

    ///
    public func cancel() {
        dispatch_async(workerQueue) {
            self.cancelWithReason(.UserRequested)
        }
    }

// MARK: Public API

    ///
    public func testStartNanos() -> UInt64 {
        return speedMeasurementResult.testStartNanos
    }

    ///
    public func medianPingNanos() -> UInt64 { // maybe better as computed property?
        return speedMeasurementResult.medianPingNanos
    }

    ///
    public func downloadKilobitsPerSecond() -> Int {
        return Int(speedMeasurementResult.totalDownloadHistory.totalThroughput.kilobitsPerSecond())
    }

    ///
    public func uploadKilobitsPerSecond() -> Int {
        return Int(speedMeasurementResult.totalUploadHistory.totalThroughput.kilobitsPerSecond())
    }

    ///
    public func addCpuUsage(cpuUsage: Double, atNanos ns: UInt64) {
        speedMeasurementResult.addCpuUsage(cpuUsage, atNanos: ns)
    }

    ///
    public func addMemoryUsage(ramUsage: Double, atNanos ns: UInt64) {
        speedMeasurementResult.addMemoryUsage(ramUsage, atNanos: ns)
    }

}
