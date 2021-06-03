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
import ObjectMapper

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
@objc public enum RMBTTestRunnerPhase: Int {
    case none = 0
    case fetchingTestParams
    case wait
    case Init
    case latency
    case down
    case initUp
    case up
    case jitter
    case packLoss
    case submittingTestResult
}

///
@objc public enum RMBTTestRunnerCancelReason: Int {
    case userRequested
    case noConnection
    case mixedConnectivity
    case errorFetchingTestingParams
    case errorSubmittingTestResult
    case appBackgrounded
}

///
@objc public protocol RMBTTestRunnerDelegate {

    ///
    func testRunnerDidStartPhase(_ phase: RMBTTestRunnerPhase)

    ///
    func testRunnerDidFinishPhase(_ phase: RMBTTestRunnerPhase)

    /// progress from 0.0 to 1.0
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

@objc protocol RMBTMainTestExtendedDelegate {
    
    func runVOIPTest()
    func shouldRunQOSTest() -> Bool

}

///
open class RMBTTestRunner: NSObject, RMBTTestWorkerDelegate, RMBTConnectivityTrackerDelegate {
    ///
    private let workerQueue: DispatchQueue = DispatchQueue(label: "at.rtr.rmbt.testrunner") // We perform all work on this background queue. Workers also callback onto this queue.

    ///
    private var timer: DispatchSourceTimer!
    private var progressTimer: GCDProgressTimer?

    ///
    private var workers: [RMBTTestWorker] = []

    ///
    private weak var delegate: RMBTTestRunnerDelegate?

    ///
    private var phase: RMBTTestRunnerPhase = .none

    ///
    private var dead = false
    
    ///////////////////////////////////
    weak var del: RMBTMainTestExtendedDelegate?
    
    ////
    var jpl: SpeedMeasurementJPLResult? {
        
        didSet {
            resultObject().jpl = jpl
//            submitResult()
        }
    
    }
    
    ///
    internal var jitterFinalValue : UInt64?
    
    ///
    internal var packLossFinalValue : UInt64?

    /// Flag indicating that downlink pretest in one of the workers was too slow and we need to
    /// continue with a single thread only
    private var singleThreaded = false

    ///
    open var testParams: SpeedMeasurementResponse!
    
    internal var loopModeUUID: String?

    ///
    private let speedMeasurementResult = SpeedMeasurementResult(resolutionNanos: UInt64(RMBT_TEST_SAMPLING_RESOLUTION_MS) * NSEC_PER_MSEC) // TODO: remove public, maker better api

    ///
    private lazy var connectivityTracker: RMBTConnectivityTracker = RMBTConnectivityTracker(delegate: self, stopOnMixed: true)

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
    open var isNewVersion = false
    open var isStoreZeroMeasurement = false
    
    private let controlServerHelper = ControlServerHelper()

    ///
    public init(delegate: RMBTTestRunnerDelegate) {
        
        //self.phase = .None
        super.init()
        self.delegate = delegate
        /*
        void *nonNullValue = kWorkerQueueIdentityKey;
        dispatch_queue_set_specific(_workerQueue, kWorkerQueueIdentityKey, nonNullValue, NULL);
        */
        //dispatch_queue_set_specific(workerQueue, kWorkerQueueIdentityKey, nil, nil) // TODO!

        connectivityTracker.start()
    }

    open func continueFromDownload() {
        if markWorkerAsFinished() {
            self.startDownlinkTest()
        }
    }
    
    /// Run on main queue (called from VC)
    open func start() {
        assert(phase == .none, "Invalid state")
        assert(!dead, "Invalid state")

        self.fetchTestParams(completionHandler: { [weak self] (response, error) in
            guard let response = response else {
                self?.cancelWithReason(.errorFetchingTestingParams, error: error)
                return
            }
            
            self?.continueWithTestParams(response)
        })

        // Notice that we post previous counter (the test before this one) when requesting the params
        RMBTSettings.sharedSettings.testCounter += 1
    }
    
    func fetchTestParams(completionHandler: @escaping (_ result: SpeedMeasurementResponse?, _ error: Error?) -> Void) {
        phase = .fetchingTestParams
        DispatchQueue.main.async {
            self.delegate?.testRunnerDidStartPhase(.fetchingTestParams)
            self.delegate?.testRunnerDidUpdateProgress(0.0, inPhase: .fetchingTestParams)
        }
        controlServerHelper.requestSpeedMeasurement(completionHandler: { [weak self] result, error in
            DispatchQueue.main.async {
                self?.delegate?.testRunnerDidUpdateProgress(1.0, inPhase: .fetchingTestParams)
                self?.delegate?.testRunnerDidFinishPhase(.fetchingTestParams)
            }
            self?.workerQueue.async(execute: {
                completionHandler(result, error)
            })
        })
    }

    ///
    private func continueWithTestParams(_ testParams: SpeedMeasurementResponse/*RMBTTestParams*/) {
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
                name: UIApplication.didEnterBackgroundNotification,
                object: nil
            )
        #endif

        // Register as observer for location tracker updates
        NotificationCenter.default.addObserver(self, selector: #selector(RMBTTestRunner.locationsDidChange(_:)), name: NSNotification.Name(rawValue: "RMBTLocationTrackerNotification"), object: nil)

        // ..and force an update right away
        RMBTLocationTracker.sharedTracker.forceUpdate()
        connectivityTracker.forceUpdate()

        if testParams.testWait > 0 {
            // Let progress timer run, then start init
            DispatchQueue.main.async {
                self.delegate?.testRunnerDidStartPhase(.wait)
                self.delegate?.testRunnerDidUpdateProgress(0.0, inPhase: .wait)
            }
            
            self.wait(duration: testParams.testWait, progressHandler: { [weak self] percent in
                self?.delegate?.testRunnerDidUpdateProgress(percent, inPhase: .wait)
            }, completionHandler: { [weak self] in
                DispatchQueue.main.async {
                    self?.delegate?.testRunnerDidUpdateProgress(1.0, inPhase: .wait)
                    self?.delegate?.testRunnerDidFinishPhase(.wait)
                }
                
                self?.startInitPhase()
            })
        } else {
            startInitPhase()
        }
    }
    
    func wait(duration: TimeInterval, progressHandler:@escaping (_ percent: Float) -> Void,  completionHandler:@escaping () -> Void) {
        if (progressTimer != nil) {
            progressTimer?.stop()
        }
        
        progressTimer = GCDProgressTimer(with: duration, progress: progressHandler, complete: { _ in
            completionHandler()
        })

        progressTimer?.start()
    }
    
    func startInitPhase() {
        let percentAfterWait: Float = Float(testParams.pretestDuration / (testParams.pretestDuration + RMBT_TEST_SOCKET_TIMEOUT_S))
        
        let phaseExecutor = { [weak self] in
            guard let `self` = self else { return }
            self.phase = .Init
            self.activeWorkers = UInt(self.workers.count)
            var finishedWorkers: Float = 0
            let percentForWorker = (1.0 - percentAfterWait) / Float(self.workers.count)
            for w in self.workers {
                w.startDownlinkPretest(complete: { [weak self] duration, chunks in
                    finishedWorkers += 1
                    let currentPercent = percentAfterWait + percentForWorker * finishedWorkers
                    self?.delegate?.testRunnerDidUpdateProgress(currentPercent, inPhase: .Init)
                    self?.finishInitPhase(with: w, duration: duration, chunks: chunks, complete: { [weak self] in
                        DispatchQueue.main.async {
                            self?.delegate?.testRunnerDidUpdateProgress(1.0, inPhase: .Init)
                            self?.delegate?.testRunnerDidFinishPhase(.Init)
                        }
                        self?.startLatencyPhase()
                    })
                })
            }
        }
        
        if testParams.pretestDuration > 0 {
            // Let progress timer run, then start init
            DispatchQueue.main.async {
                self.delegate?.testRunnerDidStartPhase(.Init)
                self.delegate?.testRunnerDidUpdateProgress(0.0, inPhase: .Init)
            }
            
            self.wait(duration: testParams.testWait, progressHandler: { [weak self] percent in
                self?.delegate?.testRunnerDidUpdateProgress(percent * percentAfterWait, inPhase: .Init)
                }, completionHandler: { [weak self] in
                    DispatchQueue.main.async {
                        self?.delegate?.testRunnerDidUpdateProgress(percentAfterWait, inPhase: .Init)
                        phaseExecutor()
                    }
            })
        } else {
            DispatchQueue.main.async {
                self.delegate?.testRunnerDidStartPhase(.Init)
                self.delegate?.testRunnerDidUpdateProgress(0.0, inPhase: .Init)
            }
            phaseExecutor()
        }
    }
    
    func finishInitPhase(with worker: RMBTTestWorker, duration: UInt64, chunks: UInt64, complete: () -> Void = {}) {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .Init, "Invalid state")
        assert(!dead, "Invalid state")
        
        //should it be calculated init time recent time - start test time
        delegate?.testRunnerDidFinishInit(duration)
        
        Log.logger.debug("Thread \(worker.index): finished download pretest (chunks = \(chunks))")
        
        if !singleThreaded && chunks <= UInt(testParams.pretestMinChunkCountForMultithreading) {
            singleThreaded = true
        }
        
        if markWorkerAsFinished() {
            if singleThreaded {
                Log.logger.debug("Downloaded <= \(self.testParams.pretestMinChunkCountForMultithreading) chunks in the pretest, continuing with single thread.")
                
                activeWorkers = UInt(testParams.numThreads) - 1
                finishedWorkers = 0
                
                for i in 1..<testParams.numThreads {
                    workers[Int(i)].stop()
                }
                
                speedMeasurementResult.startDownloadWithThreadCount(1)
                
            } else {
                speedMeasurementResult.startDownloadWithThreadCount(Int(testParams.numThreads))
                complete()
            }
        }
    }
    
    func startLatencyPhase() {
        self.phase = .latency
        DispatchQueue.main.async {
            self.delegate?.testRunnerDidStartPhase(.latency)
            self.delegate?.testRunnerDidUpdateProgress(0.0, inPhase: .latency)
        }
        
        activeWorkers = 1
        finishedWorkers = 0
        workers.first?.startLatencyTest(progress: { [weak self] percent, serverNanos, clientNanos in
            DispatchQueue.main.async {
                print("latency percent")
                print(percent)
                self?.delegate?.testRunnerDidUpdateProgress(percent, inPhase: .latency)
            }
            
            guard let `self` = self else { return }
            assert(self.phase == .latency, "Invalid state")
            assert(!self.dead, "Invalid state")
            
            self.speedMeasurementResult.addPingWithServerNanos(serverNanos, clientNanos: clientNanos)
        }, complete: { [weak self] in
            guard let `self` = self else { return }
            DispatchQueue.main.async {
                self.delegate?.testRunnerDidUpdateProgress(1.0, inPhase: .latency)
                self.delegate?.testRunnerDidFinishPhase(.latency)
            }
            
            if self.isNewVersion {
                self.del?.runVOIPTest() //TODO: Remake to call run Packet Loss and Jitter tests
                self.phase = .jitter
            }
            else {
                if self.markWorkerAsFinished() {
                    self.startDownlinkTest()
                }
            }
        })
    }

    func startDownlinkTest() {
        startPhase(.down, withAllWorkers: true, performingSelector: #selector(RMBTTestWorker.startDownlinkTest), expectedDuration: testParams.duration, completion: nil)
    }

// MARK: Test worker delegate method

    ///
    open func testWorkerDidStop(_ worker: RMBTTestWorker) {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .Init, "Invalid state")
        assert(!dead, "Invalid state")

        Log.logger.debug("Thread \(worker.index): stopped")

        workers.remove(at: workers.firstIndex(of: worker)!) // !

        if markWorkerAsFinished() {
            // We stopped all but one workers because of slow connection. Proceed to latency with single worker.
            self.startLatencyPhase()
//            startPhase(.latency, withAllWorkers: false, performingSelector: #selector(RMBTTestWorker.startLatencyTest), expectedDuration: 0, completion: nil)
        }
    }

    open func testWorker(_ worker: RMBTTestWorker, startPing: Int, totalPings: Int) {
    }
//    ///
//    open func testWorkerDidFinishLatencyTest(_ worker: RMBTTestWorker) {
//        //ASSERT_ON_WORKER_QUEUE();
//        assert(phase == .latency, "Invalid state")
//        assert(!dead, "Invalid state")
//
//        if isNewVersion {
//            del?.runVOIPTest()
//        }
//        else {
//            if markWorkerAsFinished() {
//                startPhase(.down, withAllWorkers: true, performingSelector: #selector(RMBTTestWorker.startDownlinkTest), expectedDuration: testParams.duration, completion: nil)
//            }
//        }
//    }

    ///
    open func testWorker(_ worker: RMBTTestWorker, didStartDownlinkTestAtNanos nanos: UInt64) -> UInt64 {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .down, "Invalid state")
        assert(!dead, "Invalid state")

        if downlinkTestStartedAtNanos == 0 {
            downlinkStartInterfaceInfo = speedMeasurementResult.lastConnectivity()?.getInterfaceInfo()
            downlinkTestStartedAtNanos = nanos
        }

        Log.logger.debug("Thread \(worker.index): started downlink test with delay \(nanos - self.downlinkTestStartedAtNanos)")

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
                self.delegate?.testRunnerDidMeasureThroughputs((measuredThroughputs as NSArray?)!, inPhase: .down)
            }
        }
    }

    ///
    open func testWorkerDidFinishDownlinkTest(_ worker: RMBTTestWorker) {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .down, "Invalid state")
        assert(!dead, "Invalid state")

        if markWorkerAsFinished() {
            Log.logger.debug("Downlink test finished")

            downlinkEndInterfaceInfo = speedMeasurementResult.lastConnectivity()?.getInterfaceInfo()

            let measuredThroughputs = speedMeasurementResult.flush()

            speedMeasurementResult.totalDownloadHistory.log()

            if let _ = measuredThroughputs {
                DispatchQueue.main.async {
                    self.delegate?.testRunnerDidMeasureThroughputs((measuredThroughputs as NSArray?)!, inPhase: .down)
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

        Log.logger.debug("Thread \(worker.index): finished uplink pretest (chunks = \(chunks))")

        if markWorkerAsFinished() {
            Log.logger.debug("Uplink pretest finished")
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

        Log.logger.debug("Thread \(worker.index): started uplink test with delay \(delay)")

        return delay
    }

    ///
    open func testWorker(_ worker: RMBTTestWorker, didUploadLength length: UInt64, atNanos nanos: UInt64) {
        //ASSERT_ON_WORKER_QUEUE();
        assert(phase == .up, "Invalid state")
        assert(!dead, "Invalid state")

        if let measuredThroughputs = speedMeasurementResult.addLength(length, atNanos: nanos, forThreadIndex: Int(worker.index)) {
            DispatchQueue.main.async {
                self.delegate?.testRunnerDidMeasureThroughputs(measuredThroughputs as NSArray, inPhase: .up)
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
            Log.logger.debug("Uplink test finished.")

            speedMeasurementResult.totalUploadHistory.log()

            if let _ = measuredThroughputs {
                DispatchQueue.main.async {
                    self.delegate?.testRunnerDidMeasureThroughputs((measuredThroughputs as NSArray?)!, inPhase: .up)
                }
            }
            
            /// ONT added
//            if isNewVersion {
////                if del?.shouldRunQOSTest() == true {
//                    /////////
//                    del?.runVOIPTest()
////                }
////                else {
////                    submitResult()
////                }
//
//            } else {
                submitResult()
//            }

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
    private func submitResult() {
        workerQueue.async {
            if self.dead {
                return
            }

            self.setPhase(.submittingTestResult)

            let speedMeasurementResultRequest = self.resultObject()
            
            let controlServer = ControlServer.sharedControlServer

            controlServer.submitSpeedMeasurementResult(speedMeasurementResultRequest, success: { [weak self] response in
                self?.workerQueue.async {
                    self?.setPhase(.none)
                    self?.dead = true
                    
                    RMBTSettings.sharedSettings.previousTestStatus = RMBTTestStatus.Ended.rawValue
                    
                    if let uuid = self?.testParams.testUuid {
                        DispatchQueue.main.async {
                            self?.delegate?.testRunnerDidCompleteWithResult(uuid)
                        }
                    } else {
                        self?.workerQueue.async {
                            self?.cancelWithReason(.errorSubmittingTestResult) // TODO
                        }
                    }
                }
            }, error: { [weak self] error in
                self?.workerQueue.async {
                    self?.cancelWithReason(.errorSubmittingTestResult)
                }
            })
        }
    }

    ///
    private func resultObject() -> SpeedMeasurementResult {
        speedMeasurementResult.token = testParams?.testToken ?? ""
        speedMeasurementResult.uuid = testParams?.testUuid ?? ""
        speedMeasurementResult.loopUuid = loopModeUUID

        //speedMeasurementResultRequest.portRemote =

        speedMeasurementResult.time = Date()

        // Collect total transfers from all threads
        var sumBytesDownloaded: UInt64 = 0
        var sumBytesUploaded: UInt64 = 0

        for w in workers {
            sumBytesDownloaded += w.totalBytesDownloaded
            sumBytesUploaded += w.totalBytesUploaded
        }

        //It's already not actual. Because we can have zero measurement result
//        assert(sumBytesDownloaded > 0, "Total bytes downloaded <= 0")
//        assert(sumBytesUploaded > 0, "Total bytes uploaded <= 0")

        if let firstWorker = workers.first {
            speedMeasurementResult.totalBytesDownload = NSNumber(value: sumBytesDownloaded).intValue // TODO: ?
            speedMeasurementResult.totalBytesUpload = NSNumber(value: sumBytesUploaded).intValue // TODO: ?

            speedMeasurementResult.encryption = firstWorker.negotiatedEncryptionString

            speedMeasurementResult.ipLocal = firstWorker.localIp
            speedMeasurementResult.ipServer = firstWorker.serverIp
        }
        ////////////// 
        // Ont
        /////////////
        
        
        
        
        
        
        
        

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

        speedMeasurementResult.relativeTimeDlNs = NSNumber(value: Int64(downlinkTestStartedAtNanos) - Int64(startNanos)).intValue
        speedMeasurementResult.relativeTimeUlNs = NSNumber(value: Int64(uplinkTestStartedAtNanos) - Int64(startNanos)).intValue

        //

        speedMeasurementResult.publishPublicData = RMBTSettings.sharedSettings.publishPublicData
        if TEST_USE_PERSONAL_DATA_FUZZING {
            Log.logger.info("test result: publish_public_data: \(self.speedMeasurementResult.publishPublicData)")
        }

        //////

        speedMeasurementResult.calculate()

        return speedMeasurementResult
    }

// MARK: Utility methods

    ///
    private func setPhase(_ phase: RMBTTestRunnerPhase) {
        if self.phase != .none {
            let oldPhase = self.phase

            DispatchQueue.main.async {
                self.delegate?.testRunnerDidFinishPhase(oldPhase)
            }
        }

        self.phase = phase

        if self.phase != .none {
            DispatchQueue.main.async {
                self.delegate?.testRunnerDidStartPhase(self.phase)
            }
        }
    }

    ///
    private func startPhase(_ phase: RMBTTestRunnerPhase, withAllWorkers allWorkers: Bool, performingSelector selector: Selector!,
                            expectedDuration duration: TimeInterval, completion completionHandler: EmptyCallback!) {

        //ASSERT_ON_WORKER_QUEUE();


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

            if (timer != nil) {
                timer.cancel()
            }
            
            timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: 0), queue: DispatchQueue.global(qos: .default))
            
            timer.schedule(deadline: DispatchTime.now(),
                          repeating: RMBTTestRunnerProgressUpdateInterval,
                             leeway: DispatchTimeInterval.seconds(50))
            timer.setEventHandler { [weak self] in
                let elapsedNanos: Int64 = (Int64(RMBTCurrentNanos()) - Int64(self?.progressStartedAtNanos ?? UInt64(0.0)))
                
                if elapsedNanos > (self?.progressDurationNanos ?? UInt64(0.0))  {
                    // We've reached end of interval...
                    // ..send 1.0 progress one last time..
                    DispatchQueue.main.async {
                        self?.delegate?.testRunnerDidUpdateProgress(1.0, inPhase: phase)
                    }

                    // ..then kill the timer
                    if self?.timer != nil {
                        self?.timer.cancel() // TODO: after swift rewrite of AppDelegate one test got an exception here!
                    }
                    self?.timer = nil

                    // ..and perform completion handler, if any.
                    if self?.progressCompletionHandler != nil {
                        self?.workerQueue.async(execute: {
                            self?.progressCompletionHandler()
                            self?.progressCompletionHandler = nil
                        })
                    }
                } else {
                    let p = Double(elapsedNanos) / Double(self?.progressDurationNanos ?? UInt64(0.0))
                    assert(p <= 1.0, "Invalid percentage")

                    DispatchQueue.main.async {
                        self?.delegate?.testRunnerDidUpdateProgress(Float(p), inPhase: phase)
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
    private func markWorkerAsFinished() -> Bool {
        finishedWorkers += 1
        return finishedWorkers == activeWorkers
    }

// MARK: Connectivity tracking

    ///
    open func connectivityTrackerDidDetectNoConnectivity(_ tracker: RMBTConnectivityTracker) {
        // Ignore for now, let connection time out
        workerQueue.async {
            if self.phase != .none {
                self.cancelWithReason(.noConnection)
            }
        }
    }

    open func connectivityNetworkTypeDidChange(connectivity: RMBTConnectivity) {
        workerQueue.async {
            if self.phase != .none {
                self.cancelWithReason(.mixedConnectivity)
            }
        }
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
            self.delegate?.testRunnerDidDetectConnectivity(connectivity)
        }
    }

    ///
    open func connectivityTracker(_ tracker: RMBTConnectivityTracker, didStopAndDetectIncompatibleConnectivity connectivity: RMBTConnectivity) {
        DispatchQueue.main.async {
            self.delegate?.testRunnerDidDetectConnectivity(connectivity)
        }

        workerQueue.async {
            if self.phase != .none {
                self.cancelWithReason(.mixedConnectivity)
            }
        }
    }

// MARK: App state tracking

    ///
    @objc open func applicationDidSwitchToBackground(_ n: Notification) {
        Log.logger.debug("App backgrounded, aborting \(n)")
        workerQueue.async {
            self.cancelWithReason(.appBackgrounded)
        }
    }

// MARK: Tracking location

    ///
    @objc open func locationsDidChange(_ notification: Notification) {
        var lastLocation: CLLocation?

        for l in notification.userInfo?["locations"] as! [CLLocation] { // !
            if CLLocationCoordinate2DIsValid(l.coordinate) {
                lastLocation = l
                speedMeasurementResult.addLocation(l)

                //NSLog(@"Location updated to (%f,%f,+/- %fm, %@)", l.coordinate.longitude, l.coordinate.latitude, l.horizontalAccuracy, l.timestamp);
                Log.logger.debug("Location updated to (\(l.coordinate.longitude), \(l.coordinate.latitude), \(l.horizontalAccuracy), \(l.timestamp))")
            }
        }

        if let _ = lastLocation {
            DispatchQueue.main.async {
                self.delegate?.testRunnerDidDetectLocation(lastLocation!) // !
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
    private func cancelWithReason(_ reason: RMBTTestRunnerCancelReason, error: Error? = nil) {
        //ASSERT_ON_WORKER_QUEUE();
    
        if isStoreZeroMeasurement == true && reason != .userRequested {
            print("Store")
            let result = self.resultObject()
            if let _ = result.uuid {
                DispatchQueue.global().async {
                    let zeroMeasurement = StoredZeroMeasurement.storedZeroMeasurement(with: result)
                    zeroMeasurement.store()
                }
            }
        }
        Log.logger.debug("REASON: \(reason)")

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
            self.delegate?.testRunnerDidCancelTestWithReason(reason)
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
    open func meanJitterNanos() -> Int {
        if let inJiter = jpl?.resultInMeanJitter,
            let outJiter = jpl?.resultOutMeanJitter {
            let j = (inJiter + outJiter) / 2
            return Int(j)
        }
        return 30000
    }
    
    ///
    open func packetLossPercentage() -> Int {
        return 3
    }

    ///
    open func addCpuUsage(_ cpuUsage: Double, atNanos ns: UInt64) {
        speedMeasurementResult.addCpuUsage(cpuUsage, atNanos: ns)
    }

    ///
    open func addMemoryUsage(_ ramUsage: Double, atNanos ns: UInt64) {
        speedMeasurementResult.addMemoryUsage(ramUsage, atNanos: ns)
    }

//    var testsParameters: QosMeasurmentResponse?
//    
//    func requestParameters(completionHandler: @escaping (_ response: QosMeasurmentResponse?) -> Void) {
//        guard let uuid = self.testParams.testUuid else {
//            return
//        }
//        let controlServer = ControlServer.sharedControlServer
//        controlServer.requestQosMeasurement(self.testParams.testUuid, success: { [weak self] response in
//            self?.testsParameters = response
//            completionHandler(response)
//        }) { [weak self] error in
//            Log.logger.debug("ERROR fetching qosTestRequest")
//            
////            self?.fail(nil) // TODO: error message...
//            completionHandler(nil)
//        }
//    }
//    
//    func testPacketLose(progressHandler: (_ progress: Double) -> Void, completionHandler: (_ result: Any?, _ error: Error?) -> Void) {
//        
//    }
}
