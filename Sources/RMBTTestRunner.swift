//
//  RMBTTestRunner.swift
//  RMBT
//
//  Created by Benjamin Pucher on 09.09.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation
import CoreLocation

#if os(iOS)
    import UIKit
#endif
    
///
public let RMBTTestStatusNone              = "NONE"
public let RMBTTestStatusAborted           = "ABORTED"
public let RMBTTestStatusError             = "ERROR"
public let RMBTTestStatusErrorFetching     = "ERROR_FETCH"
public let RMBTTestStatusErrorSubmitting   = "ERROR_SUBMIT"
public let RMBTTestStatusErrorBackgrounded = "ABORTED_BACKGROUNDED"
public let RMBTTestStatusEnded             = "END"

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
    func testRunnerDidCompleteWithResult(result: RMBTHistoryResult)

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
    public var testParams: SpeedMeasurmentResponse!

    ///
    public let testResult = RMBTTestResult(resolutionNanos: UInt64(RMBT_TEST_SAMPLING_RESOLUTION_MS) * NSEC_PER_MSEC)

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
    private var progressCompletionHandler: RMBTBlock!

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
        speedMeasurementRequest.time = Int(currentTimeMillis()) // nanoTime?
        
        speedMeasurementRequest.testCounter = RMBTSettings.sharedSettings().testCounter
        speedMeasurementRequest.previousTestStatus = RMBTSettings.sharedSettings().previousTestStatus ?? RMBTTestStatusNone
        
        if let l = RMBTLocationTracker.sharedTracker.location {
            let geoLocation = GeoLocation()
            
            geoLocation.latitude = l.coordinate.latitude
            geoLocation.longitude = l.coordinate.longitude
            geoLocation.accuracy = l.horizontalAccuracy
            geoLocation.altitude = l.altitude
            geoLocation.bearing = 42 // TODO
            geoLocation.speed = (l.speed > 0.0 ? l.speed : 0.0)
            geoLocation.provider = "GPS" // TODO?
            geoLocation.relativeTimeNs = 0 // TODO?
            geoLocation.time = l.timestamp // TODO?
            
            speedMeasurementRequest.geoLocation = geoLocation
        }
        
        let controlServer = ControlServerNew.sharedControlServer
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
        RMBTSettings.sharedSettings().testCounter += 1
    }

    ///
    private func continueWithTestParams(testParams: SpeedMeasurmentResponse/*RMBTTestParams*/) {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .FetchingTestParams || phase == .None, "Invalid state")

        if dead {
            return
        }

        self.testParams = testParams

        //testResult = RMBTTestResult(resolutionNanos: UInt64(RMBT_TEST_SAMPLING_RESOLUTION_MS) * NSEC_PER_MSEC)
        testResult.markTestStart()

        for i in 0..<(testParams.numThreads ?? 0) {
            let worker = RMBTTestWorker(delegate: self, delegateQueue: workerQueue, index: UInt(i), testParams: testParams)
            workers.append(worker)
        }

        #if os(iOS)
            // Start observing app going to background notifications
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(RMBTTestRunner.applicationDidSwitchToBackground(_:)), name: UIApplicationDidEnterBackgroundNotification, object: nil)
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
                logger.debug("Downloaded <= \(testParams.pretestMinChunkCountForMultithreading) chunks in the pretest, continuing with single thread.")

                activeWorkers = UInt(testParams.numThreads) - 1
                finishedWorkers = 0

                for i in 1..<testParams.numThreads {
                    workers[Int(i)].stop()
                }

                testResult.startDownloadWithThreadCount(1)

            } else {
                testResult.startDownloadWithThreadCount(Int(testParams.numThreads))
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

        testResult.addPingWithServerNanos(serverNanos, clientNanos: clientNanos)

        let p = Double(testResult.pings.count) / Double(testParams.numPings)
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
            downlinkStartInterfaceInfo = testResult.lastConnectivity().getInterfaceInfo()
            downlinkTestStartedAtNanos = nanos
        }

        logger.debug("Thread \(worker.index): started downlink test with delay \(nanos - downlinkTestStartedAtNanos)")

        return downlinkTestStartedAtNanos
    }

    ///
    public func testWorker(worker: RMBTTestWorker, didDownloadLength length: UInt64, atNanos nanos: UInt64) {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .Down, "Invalid state")
        assert(!dead, "Invalid state")

        let measuredThroughputs = testResult.addLength(length, atNanos: nanos, forThreadIndex: Int(worker.index))

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

            downlinkEndInterfaceInfo = testResult.lastConnectivity().getInterfaceInfo()

            let measuredThroughputs = testResult.flush()

            testResult.totalDownloadHistory.log()

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
            testResult.startUpload()
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
            uplinkStartInterfaceInfo = testResult.lastConnectivity().getInterfaceInfo()
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

        if let measuredThroughputs = testResult.addLength(length, atNanos: nanos, forThreadIndex: Int(worker.index)) {
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

            uplinkEndInterfaceInfo = testResult.lastConnectivity().getInterfaceInfo()

            let measuredThroughputs = testResult.flush()
            logger.debug("Uplink test finished.")

            testResult.totalUploadHistory.log()

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

            //let result = self.resultDictionary()

            //self.phase = .SubmittingTestResult
            self.setPhase(.SubmittingTestResult)
            
            let speedMeasurementResultRequest = self.resultObject()
            
            let controlServer = ControlServerNew.sharedControlServer
            
            /*controlServer.submitSpeedMeasurementResult(speedMeasurementResultRequest, success: { response in
                dispatch_async(self.workerQueue) {
                    //self.phase = .None
                    self.setPhase(.None)
                    self.dead = true
                    
                    RMBTSettings.sharedSettings().previousTestStatus = RMBTTestStatusEnded
                    
                    let historyResult = RMBTHistoryResult(response: ["test_uuid": self.testParams.testUuid ?? ""]) // TODO
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.delegate.testRunnerDidCompleteWithResult(historyResult)
                    }
                }
            }, error: { error in
                dispatch_async(self.workerQueue) {
                    self.cancelWithReason(.ErrorSubmittingTestResult)
                }
            })*/
            
            let successFunc: (response: AnyObject) -> () = { response in
                dispatch_async(self.workerQueue) {
                    //self.phase = .None
                    self.setPhase(.None)
                    self.dead = true
                    
                    RMBTSettings.sharedSettings().previousTestStatus = RMBTTestStatusEnded
                    
                    let historyResult = RMBTHistoryResult(response: ["test_uuid": self.testParams.testUuid ?? ""]) // TODO
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        self.delegate.testRunnerDidCompleteWithResult(historyResult)
                    }
                }
            }
            
            // TODO: remove this later and take code above (this lets the app continue with qos even if the speed test result is not working...)
            controlServer.submitSpeedMeasurementResult(speedMeasurementResultRequest, success: successFunc, error: { _ in
                dispatch_async(self.workerQueue) {
                    self.cancelWithReason(.ErrorSubmittingTestResult)
                }
            })
        }
    }
    
    private func resultObject() -> SpeedMeasurementResultRequest { // TODO: replace test result with SpeedMeasurementResultRequest!
        let result = NSMutableDictionary(dictionary: testResult.resultDictionary())
        
        let speedMeasurementResultRequest = SpeedMeasurementResultRequest()
        
        speedMeasurementResultRequest.token = testParams.testToken
        speedMeasurementResultRequest.uuid = testParams.testUuid
        
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
            speedMeasurementResultRequest.bytesDownload = NSNumber(unsignedLongLong: sumBytesDownloaded).integerValue // TODO: ?
            speedMeasurementResultRequest.bytesUpload = NSNumber(unsignedLongLong: sumBytesUploaded).integerValue // TODO: ?
                
            speedMeasurementResultRequest.encryption = firstWorker.negotiatedEncryptionString
                
            speedMeasurementResultRequest.ipLocal = firstWorker.localIp
            speedMeasurementResultRequest.ipServer = firstWorker.serverIp
        }
        
        result.addEntriesFromDictionary(interfaceBytesResultDictionaryWithStartInfo(downlinkStartInterfaceInfo!, endInfo: downlinkEndInterfaceInfo!, prefix: "testdl"))
        result.addEntriesFromDictionary(interfaceBytesResultDictionaryWithStartInfo(uplinkStartInterfaceInfo!,   endInfo: uplinkEndInterfaceInfo!,   prefix: "testul"))
        result.addEntriesFromDictionary(interfaceBytesResultDictionaryWithStartInfo(startInterfaceInfo!,         endInfo: uplinkEndInterfaceInfo!,   prefix: "test"))
        
        // Add relative time_(dl/ul)_ns timestamps
        let startNanos = testResult.testStartNanos
        
        speedMeasurementResultRequest.relativeTimeDlNs = NSNumber(unsignedLongLong: downlinkTestStartedAtNanos - startNanos).integerValue
        speedMeasurementResultRequest.relativeTimeUlNs = NSNumber(unsignedLongLong: uplinkTestStartedAtNanos - startNanos).integerValue
        
        ////////////////////////////////////////////////////////////////////
        // TODO: improve this (needs cleanup afterwards)
        speedMeasurementResultRequest.numThreads = testParams.numThreads
        speedMeasurementResultRequest.numThreadsUl = testParams.numThreads // TODO?
        
        speedMeasurementResultRequest.pings = testResult.pings
        
        //speedMeasurementResultRequest.extendedTestStat = // TODO
        
        for l in (result["geoLocations"] as? [[String: NSNumber]])! {
            let geoLocation = GeoLocation()
            
            geoLocation.latitude = l["geo_lat"]?.doubleValue
            geoLocation.longitude = l["geo_long"]?.doubleValue
            geoLocation.accuracy = l["accuracy"]?.doubleValue
            geoLocation.altitude = l["altitude"]?.doubleValue
            //geoLocation.bearing =
            geoLocation.speed = l["speed"]?.doubleValue
            //geoLocation.provider =
            geoLocation.relativeTimeNs = l["time_ns"]?.integerValue
            //geoLocation.time =
            
            speedMeasurementResultRequest.geoLocations.append(geoLocation)
        }
        
        for s in (result["speed_detail"] as? [[String: AnyObject]])! {
            let speedRawItem = SpeedRawItem()
            
            speedRawItem.direction = SpeedRawItem.SpeedRawItemDirection(rawValue: (s["direction"] as? String) ?? "download")
            speedRawItem.thread = (s["thread"] as? NSNumber)?.integerValue ?? 0
            speedRawItem.time = (s["time"] as? NSNumber)?.integerValue ?? 0
            speedRawItem.bytes = (s["bytes"] as? NSNumber)?.integerValue ?? 0
            
            speedMeasurementResultRequest.speedDetail.append(speedRawItem)
        }
        
        speedMeasurementResultRequest.networkType = (result["network_type"] as? NSNumber)?.integerValue ?? -1
        
        /*
        speedMeasurementResultRequest.durationUploadNs =
        speedMeasurementResultRequest.durationDownloadNs =
        
        speedMeasurementResultRequest.pingShortest =
        speedMeasurementResultRequest.portRemote =
        speedMeasurementResultRequest.speedDownload =
        speedMeasurementResultRequest.speedUpload =
        
        speedMeasurementResultRequest.totalBytesDownload =
        speedMeasurementResultRequest.totalBytesUpload =
        speedMeasurementResultRequest.interfaceTotalBytesDownload =
        speedMeasurementResultRequest.interfaceTotalBytesUpload =
        speedMeasurementResultRequest.interfaceDltestBytesDownload =
        speedMeasurementResultRequest.interfaceDltestBytesUpload =
        speedMeasurementResultRequest.interfaceUltestBytesDownload =
        speedMeasurementResultRequest.interfaceUltestBytesUpload =
        speedMeasurementResultRequest.time =
        speedMeasurementResultRequest.telephonyInfo =
        speedMeasurementResultRequest.wifiInfo =*/

        if TEST_USE_PERSONAL_DATA_FUZZING {
            speedMeasurementResultRequest.publishPublicData = RMBTSettings.sharedSettings().publishPublicData
            logger.info("test result: publish_public_data: \(speedMeasurementResultRequest.publishPublicData)")
        }
        
        //////
        
        return speedMeasurementResultRequest
    }

    ///
    private func resultDictionary() -> /*[NSObject:AnyObject]*/NSDictionary {
        let result = NSMutableDictionary(dictionary: testResult.resultDictionary())

        result["test_token"] = testParams.testToken

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
            result.addEntriesFromDictionary([
                "test_total_bytes_download": NSNumber(unsignedLongLong: sumBytesDownloaded),
                "test_total_bytes_upload":   NSNumber(unsignedLongLong: sumBytesUploaded),
                "test_encryption":           firstWorker.negotiatedEncryptionString,
                "test_ip_local":             RMBTValueOrNull(firstWorker.localIp),
                "test_ip_server":            RMBTValueOrNull(firstWorker.serverIp),
            ])
        }

        result.addEntriesFromDictionary(interfaceBytesResultDictionaryWithStartInfo(downlinkStartInterfaceInfo!, endInfo: downlinkEndInterfaceInfo!, prefix: "testdl"))
        result.addEntriesFromDictionary(interfaceBytesResultDictionaryWithStartInfo(uplinkStartInterfaceInfo!,   endInfo: uplinkEndInterfaceInfo!,   prefix: "testul"))
        result.addEntriesFromDictionary(interfaceBytesResultDictionaryWithStartInfo(startInterfaceInfo!,         endInfo: uplinkEndInterfaceInfo!,   prefix: "test"))

        // Add relative time_(dl/ul)_ns timestamps
        let startNanos = testResult.testStartNanos

        result.addEntriesFromDictionary([
            "time_dl_ns": NSNumber(unsignedLongLong: downlinkTestStartedAtNanos - startNanos),
            "time_ul_ns": NSNumber(unsignedLongLong: uplinkTestStartedAtNanos - startNanos)
        ])

        return result
    }

    ///
    private func interfaceBytesResultDictionaryWithStartInfo(startInfo: RMBTConnectivityInterfaceInfo, endInfo: RMBTConnectivityInterfaceInfo, prefix: String) -> [NSObject:AnyObject] {
        if startInfo.bytesReceived <= endInfo.bytesReceived && startInfo.bytesSent < endInfo.bytesSent {
            return [
                "\(prefix)_if_bytes_download":  NSNumber(unsignedLongLong: UInt64(endInfo.bytesReceived - startInfo.bytesReceived)),
                "\(prefix)_if_bytes_upload":    NSNumber(unsignedLongLong: UInt64(endInfo.bytesSent - startInfo.bytesSent))
            ]
        } else {
            return [:]
        }
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
                            expectedDuration duration: NSTimeInterval, completion completionHandler: RMBTBlock!) {

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
            if self.testResult.lastConnectivity() == nil { // TODO: error here?
                self.startInterfaceInfo = connectivity.getInterfaceInfo()
            }

            if self.phase != .None {
                self.testResult.addConnectivity(connectivity)
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
                testResult.addLocation(l)

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
            RMBTSettings.sharedSettings().previousTestStatus = RMBTTestStatusAborted
        case .AppBackgrounded:
            RMBTSettings.sharedSettings().previousTestStatus = RMBTTestStatusErrorBackgrounded
        case .ErrorFetchingTestingParams:
            RMBTSettings.sharedSettings().previousTestStatus = RMBTTestStatusErrorFetching
        case .ErrorSubmittingTestResult:
            RMBTSettings.sharedSettings().previousTestStatus = RMBTTestStatusErrorSubmitting
        default:
            RMBTSettings.sharedSettings().previousTestStatus = RMBTTestStatusError
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
}
