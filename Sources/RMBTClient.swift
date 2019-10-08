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
import CoreLocation

///
public enum SpeedMeasurementPhase: Int {
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

    ///
    public static func mapFromRmbtRunnerPhase(_ phase: RMBTTestRunnerPhase) -> SpeedMeasurementPhase { // TODO: improve
        return SpeedMeasurementPhase.init(rawValue: phase.rawValue)!
    }
}

///
public enum RMBTClientCancelReason: Int {
    case unknownError = 0
    case userRequested
    case appBackgrounded

    case noConnection
    case mixedConnectivity

    case errorFetchingSpeedMeasurementParams
    case errorSubmittingSpeedMeasurement

    case errorFetchingQosMeasurementParams
    case errorSubmittingQosMeasurement

    ///
    public static func mapFromSpeedMesurementCancelReason(_ cancelReason: RMBTTestRunnerCancelReason) -> RMBTClientCancelReason { // TODO: improve
        switch cancelReason {
        case .userRequested: return .userRequested
        case .appBackgrounded: return .appBackgrounded
        case .mixedConnectivity: return .mixedConnectivity
        case .noConnection: return .noConnection
        case .errorFetchingTestingParams: return .errorFetchingSpeedMeasurementParams
        case .errorSubmittingTestResult: return .errorSubmittingSpeedMeasurement
        }
    }
}

///
public protocol RMBTClientDelegate {

    ///
    func measurementDidStart(client: RMBTClient)
    
    ///
    func measurementDidCompleteVoip(_ client: RMBTClient, withResult: [String:Any])

    ///
    func measurementDidComplete(_ client: RMBTClient, withResult result: String)

    ///
    func measurementDidFail(_ client: RMBTClient, withReason reason: RMBTClientCancelReason)

// MARK: Speed
    
    ///
    func speedMeasurementDidUpdateWith(progress: Float, inPhase phase: SpeedMeasurementPhase)

    /// testRunnerDidMeasureThroughputs
    // func speedMeasurementDidMeasureSpeed(_ kbps: Int, inPhase phase: SpeedMeasurementPhase)
    func speedMeasurementDidMeasureSpeed(throughputs: [RMBTThroughput], inPhase phase: SpeedMeasurementPhase)

    ///
    func speedMeasurementDidStartPhase(_ phase: SpeedMeasurementPhase)

    ///
    func speedMeasurementDidFinishPhase(_ phase: SpeedMeasurementPhase, withResult result: Double)

// MARK: Qos

    ///
    func qosMeasurementDidStart(_ client: RMBTClient)

    ///
    func qosMeasurementDidUpdateProgress(_ client: RMBTClient, progress: Float)
    
    
    
    /// new
    func qosMeasurementList(_ client: RMBTClient, list: [QosMeasurementType])
    
    ///
    func qosMeasurementFinished(_ client: RMBTClient, type: QosMeasurementType)
}

//
public enum RMBTClientType {
    ///
    case original // delay, down, up + QoS
    case standard // delay, down, up, jitter, packet loss + QoS
    case nkom // delay, down, up + QoS
}

/////////////

///
open class RMBTClient: RMBTMainTestExtendedDelegate {
    
    // RMBTMainTestExtendedDelegate
    func runVOIPTest() {
        startQosMeasurement(inMain: true)
    }
    
    func shouldRunQOSTest() -> Bool {
        return self.isQOSEnabled
    }

    ///
    open var testRunner: RMBTTestRunner?
    
    /// init
    private var clientType: RMBTClientType = .standard

    ///
    internal var qualityOfServiceTestRunner: QualityOfServiceTest?

    ///
    open var delegate: RMBTClientDelegate?
    
    open var isStoreZeroMeasurement = false
    
    open var isQOSEnabled = false

    ///
    var resultUuid: String?
    
    open var loopModeUUID: String? {
        didSet {
            self.testRunner?.loopModeUUID = loopModeUUID
        }
    }

    ///
    open var running: Bool {
        get { return _running }
    }

    ///
    var _running = false

    /// used for updating cpu and memory usage
    private var hardwareUsageTimer: Timer?
    

    ///
    private let cpuMonitor = RMBTCPUMonitor()

    ///
    private let ramMonitor = RMBTRAMMonitor()

    ///
    public init(withClient:RMBTClientType) {
        //
        defer {
            clientType = withClient
        }
    }

    ///
    open func startMeasurement() {
        startSpeedMeasurement()
        testRunner?.del = self
    }

    ///
    open func stopMeasurement() {
        testRunner?.cancel()
        qualityOfServiceTestRunner?.stop()

        _running = false
    }

    ///
    private func startSpeedMeasurement() {
        testRunner = RMBTTestRunner(delegate: self)
        testRunner?.isStoreZeroMeasurement = self.isStoreZeroMeasurement
        testRunner?.loopModeUUID = self.loopModeUUID
        testRunner?.start()
        
        if clientType == .standard {
            testRunner?.isNewVersion = true
        }

        _running = true

        startHardwareUsageTimer()
    }

    ///
    open func startQosMeasurement(inMain: Bool) {
        if let testToken = testRunner?.testParams.testToken,
               let measurementUuid = testRunner?.testParams.testUuid,
               let testStartNanos = testRunner?.testStartNanos() {
            
            if inMain == true {
                DispatchQueue.main.async {
                    self.testRunnerDidStartPhase(.jitter)
                    self.testRunnerDidUpdateProgress(0.0, inPhase: .jitter)
                }
            }

            qualityOfServiceTestRunner = QualityOfServiceTest(testToken: testToken, measurementUuid: measurementUuid, speedtestStartTime: testStartNanos, isPartOfMainTest: inMain)

            qualityOfServiceTestRunner?.delegate = self

            _running = true
            qualityOfServiceTestRunner?.start()
        }
    }

    ///
    func finishMeasurement() {
        _running = false

        if let uuid = self.resultUuid {
            MeasurementHistory.sharedMeasurementHistory.dirty = true // set history to dirty after measurement
            
            delegate?.measurementDidComplete(self, withResult: uuid)
        } else {
            delegate?.measurementDidFail(self, withReason: RMBTClientCancelReason.unknownError) // TODO better error handling (but this error should never happen...)
        }
    }

// MARK: Hardware usage timer

    ///
    func startHardwareUsageTimer() {
        hardwareUsageTimer = Timer.scheduledTimer(timeInterval: 1,
                                                  target: self,
                                                  selector: #selector(hardwareUsageTimerFired),
                                                  userInfo: nil,
                                                  repeats: true)
    }

    ///
    func stopHardwareUsageTimer() {
        hardwareUsageTimer?.invalidate()
        hardwareUsageTimer = nil
    }

    ///
    @objc func hardwareUsageTimerFired() {
        if let testStartNanos = testRunner?.testStartNanos() {

            let relativeNanos = UInt64.nanoTime() - testStartNanos

            //////////////////
            // CPU

            if let cpuUsage = cpuMonitor.getCPUUsage() as? [NSNumber], cpuUsage.count > 0 {
                testRunner?.addCpuUsage(cpuUsage[0].doubleValue, atNanos: relativeNanos)

                Log.logger.debug("ADDING CPU USAGE: \(cpuUsage[0].floatValue) atNanos: \(relativeNanos)")
            } else {
                // TODO: else write implausible error, or use previous value
            }

            //////////////////
            // RAM

            let ramUsagePercentFree = ramMonitor.getRAMUsagePercentFree()

            testRunner?.addMemoryUsage(Double(ramUsagePercentFree), atNanos: relativeNanos)
            Log.logger.debug("ADDING RAM USAGE: \(ramUsagePercentFree) atNanos: \(relativeNanos)")
        }
    }
    
}

///
extension RMBTClient: RMBTTestRunnerDelegate {

    ///
    public func testRunnerDidDetectConnectivity(_ connectivity: RMBTConnectivity) {
        Log.logger.debug("TESTRUNNER: CONNECTIVITY")
    }

    ///
    public func testRunnerDidDetectLocation(_ location: CLLocation) {
        // TODO: do nothing?
    }

    ///
    public func testRunnerDidStartPhase(_ phase: RMBTTestRunnerPhase) {
        //Log.logger.debug("TESTRUNNER: DID START PHASE: \(phase)")
        delegate?.speedMeasurementDidStartPhase(SpeedMeasurementPhase.mapFromRmbtRunnerPhase(phase))
    }

    ///
    public func testRunnerDidFinishPhase(_ phase: RMBTTestRunnerPhase) {
        var result: Double = -1

        switch phase {
        case .latency:
            if let r = testRunner?.medianPingNanos() {
                result = Double(r)
            }
        case .down:
            if let r = testRunner?.downloadKilobitsPerSecond() {
                result = Double(r)
            }
        case .up:
            if let r = testRunner?.uploadKilobitsPerSecond() {
                result = Double(r)
            }
        case .jitter:
            if let r = testRunner?.meanJitterNanos() {
                result = Double(r)
            }
            
        case .packLoss:
            if let r = testRunner?.packetLossPercentage() {
                result = Double(r)
            }
            
        default:
            break
        }

        delegate?.speedMeasurementDidFinishPhase(SpeedMeasurementPhase.mapFromRmbtRunnerPhase(phase), withResult: result)
        //Log.logger.debug("TESTRUNNER: DID FINISH PHASE: \(phase)")
    }

    ///
    public func testRunnerDidFinishInit(_ time: UInt64) {
        //Log.logger.debug("TESTRUNNER: DID FINISH INIT: \(time)")
        self.delegate?.measurementDidStart(client: self)
    }

    ///
    public func testRunnerDidUpdateProgress(_ progress: Float, inPhase phase: RMBTTestRunnerPhase) {
        DispatchQueue.main.async {
            //Log.logger.debug("TESTRUNNER: DID UPDATE PROGRESS: \(progress)")
            self.delegate?.speedMeasurementDidUpdateWith(progress: progress, inPhase: SpeedMeasurementPhase.mapFromRmbtRunnerPhase(phase))
        }
    }

    ///
    public func testRunnerDidMeasureThroughputs(_ throughputs: NSArray, inPhase phase: RMBTTestRunnerPhase) {
        // TODO: use same logic as in android app? (RMBTClient.java:646)

//        if let throughputs = throughputs as? [RMBTThroughput], let throughput = throughputs.last { // last?
//            let kbps = throughput.kilobitsPerSecond()
//            delegate?.speedMeasurementDidMeasureSpeed(Int(kbps), inPhase: SpeedMeasurementPhase.mapFromRmbtRunnerPhase(phase))
//        }
        delegate?.speedMeasurementDidMeasureSpeed(throughputs: (throughputs as? [RMBTThroughput])!, inPhase: SpeedMeasurementPhase.mapFromRmbtRunnerPhase(phase))
    }

    ///
    public func testRunnerDidCompleteWithResult(_ uuid: String) {
        stopHardwareUsageTimer() // stop cpu and memory usage timer

        self.resultUuid = uuid

        if self.isQOSEnabled {
            startQosMeasurement(inMain: false) // continue with qos measurement
        } else {
            finishMeasurement()
        }
    }

    ///
    public func testRunnerDidCancelTestWithReason(_ cancelReason: RMBTTestRunnerCancelReason) {
        stopHardwareUsageTimer() // stop cpu and memory usage timer

        _running = false

        let reason = RMBTClientCancelReason.mapFromSpeedMesurementCancelReason(cancelReason)

        delegate?.measurementDidFail(self, withReason: reason)
    }

}

///
extension RMBTClient: QualityOfServiceTestDelegate {

    ///
    public func qualityOfServiceTestDidStart(_ test: QualityOfServiceTest) {
        if !(self.qualityOfServiceTestRunner?.isPartOfMainTest)! {
            delegate?.qosMeasurementDidStart(self)
        }
        
    }

    ///
    public func qualityOfServiceTestDidStop(_ test: QualityOfServiceTest) {
        //delegate?.measurementDidFail(self, withReason: .unknownError) // TODO: better errors
    }

    ///
    public func qualityOfServiceTest(_ test: QualityOfServiceTest, didFinishWithResults results: [QOSTestResult]) {
        // TODO: stop location tracker!

        if let mainTest = self.qualityOfServiceTestRunner?.isPartOfMainTest, mainTest {
            
            if let result = results.first?.resultDictionary {
                
                // should pass even it fails
                //                if let r = result["voip_result_status"] as? String, r == "TIMEOUT" {
                //
                //                    delegate?.measurementDidFail(self, withReason: .unknownError)
                //                    ///
                //                    return
                //                }
                
                // delegate to runner to submit VOIP results               
                self.testRunner?.jpl = SpeedMeasurementJPLResult(JSON: result)
                self.delegate?.measurementDidCompleteVoip(self, withResult: result)
                DispatchQueue.main.async {
                    self.testRunnerDidUpdateProgress(1.0, inPhase: .jitter)
                    self.testRunnerDidFinishPhase(.jitter)
                }
                self.testRunner?.continueFromDownload()
            } else {
                self.delegate?.measurementDidFail(self, withReason: .unknownError)
            }
            
        } else {
            self.finishMeasurement()
        }
    }

    ///
    public func qualityOfServiceTest(_ test: QualityOfServiceTest, didFailWithError: NSError!) {
        _running = false

        delegate?.measurementDidFail(self, withReason: .unknownError) // TODO: better errors
    }

    ///
    public func qualityOfServiceTest(_ test: QualityOfServiceTest, didFetchTestTypes testTypes: [String]) {
        //Log.logger.debug("QOS: DID FETCH TYPES: \(time)")
        if !(self.qualityOfServiceTestRunner?.isPartOfMainTest)! {
            
            if testTypes.count > 0 {
                delegate?.qosMeasurementList(self, list: testTypes.map({ (string) -> QosMeasurementType in
                    if let type = QosMeasurementType(rawValue: string) {
                        return type
                    }
                    else {
                        return QosMeasurementType.HttpProxy
                    }
                }))
            } else {
                //
                delegate?.measurementDidFail(self, withReason: .errorFetchingQosMeasurementParams)
            }
        }
    }

    ///
    public func qualityOfServiceTest(_ test: QualityOfServiceTest, didFinishTestType testType: String) {
        //Log.logger.debug("QOS: DID FINISH TYPE: \(time)")
        if !(self.qualityOfServiceTestRunner?.isPartOfMainTest)! {
            self.delegate?.qosMeasurementFinished(self, type: QosMeasurementType(rawValue: testType) ?? QosMeasurementType.HttpProxy)
        }
    }

    ///
    public func qualityOfServiceTest(_ test: QualityOfServiceTest, didProgressToValue progress: Float) {
        DispatchQueue.main.async {
            if self.qualityOfServiceTestRunner?.isPartOfMainTest == true {
                self.delegate?.speedMeasurementDidUpdateWith(progress: progress, inPhase: .jitter)
            } else {
                self.delegate?.qosMeasurementDidUpdateProgress(self, progress: progress)
            }
        }
    }

}

// MARK: ControlServer proxy methods

///
extension RMBTClient {
    ///
    public class func refreshSettings() {
        MeasurementHistory.sharedMeasurementHistory.dirty = true // set history to dirty for changed control servers
        RMBTConfig.updateSettings(success: {
        
        }, error: { error in
        
        })
    }

    ///
    public class var uuid: String? {
        get {
            return ControlServer.sharedControlServer.uuid
        }
    }
    
    ///
    public class var surveyTimestamp: TimeInterval? {
        get {
            return TimeInterval(ControlServer.sharedControlServer.surveySettings?.dateStarted ?? 0)
        }
    }
    
    public class var surveyUrl: String? {
        get {
            return ControlServer.sharedControlServer.surveySettings?.surveyUrl
        }
    }
    
    public class var surveyIsActiveService: Bool? {
        get {
            return ControlServer.sharedControlServer.surveySettings?.isActiveService
        }
    }
    
    public class var advertisingIsActive: Bool {
        get {
            return ControlServer.sharedControlServer.advertisingSettings?.isShowAdvertising ?? false
        }
    }
    
    public class var advertisingSettings: AdvertisingResponse? {
        get {
            return ControlServer.sharedControlServer.advertisingSettings
        }
    }

    ///
    public class var controlServerVersion: String? {
        get {
            return ControlServer.sharedControlServer.version
        }
    }

}
