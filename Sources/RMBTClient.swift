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
        case .userRequested:
            return .userRequested
        case .appBackgrounded:
            return .appBackgrounded
        case .mixedConnectivity:
            return .mixedConnectivity
        case .noConnection:
            return .noConnection
        case .errorFetchingTestingParams:
            return .errorFetchingSpeedMeasurementParams
        case .errorSubmittingTestResult:
            return .errorSubmittingSpeedMeasurement
        }
    }
}

///
public protocol RMBTClientDelegate {

    ///
    //func measurementDidStart(client: RMBTClient)

    ///
    func measurementDidComplete(_ client: RMBTClient, withResult result: String)

    ///
    func measurementDidFail(_ client: RMBTClient, withReason reason: RMBTClientCancelReason)

// MARK: Speed

    ///
    func speedMeasurementDidMeasureSpeed(_ kbps: Int, inPhase phase: SpeedMeasurementPhase)

    ///
    func speedMeasurementDidStartPhase(_ phase: SpeedMeasurementPhase)

    ///
    func speedMeasurementDidFinishPhase(_ phase: SpeedMeasurementPhase, withResult result: Int)

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

/////////////

///
open class RMBTClient {

    ///
    open var testRunner: RMBTTestRunner?

    ///
    private var qualityOfServiceTestRunner: QualityOfServiceTest?

    ///
    open var delegate: RMBTClientDelegate?

    ///
    var resultUuid: String?

    ///
    open var running: Bool {
        get {
            return _running
        }
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
    public init() {

    }

    ///
    open func startMeasurement() {
        startSpeedMeasurement()
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
        testRunner?.start()

        _running = true

        // startHardwareUsageTimer() // start cpu and memory usage timer // NO need for NKOM
    }

    ///
    func startQosMeasurement() {
        if let testToken = testRunner?.testParams.testToken,
               let measurementUuid = testRunner?.testParams.testUuid,
               let testStartNanos = testRunner?.testStartNanos() {

            qualityOfServiceTestRunner = QualityOfServiceTest(testToken: testToken, measurementUuid: measurementUuid, speedtestStartTime: testStartNanos)

            qualityOfServiceTestRunner?.delegate = self

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

            let relativeNanos = nanoTime() - testStartNanos

            //////////////////
            // CPU

            if let cpuUsage = cpuMonitor.getCPUUsage() as? [NSNumber], cpuUsage.count > 0 {
                testRunner?.addCpuUsage(cpuUsage[0].doubleValue, atNanos: relativeNanos)

                logger.debug("ADDING CPU USAGE: \(cpuUsage[0].floatValue) atNanos: \(relativeNanos)")
            } else {
                // TODO: else write implausible error, or use previous value
            }

            //////////////////
            // RAM

            let ramUsagePercentFree = ramMonitor.getRAMUsagePercentFree()

            testRunner?.addMemoryUsage(Double(ramUsagePercentFree), atNanos: relativeNanos)
            logger.debug("ADDING RAM USAGE: \(ramUsagePercentFree) atNanos: \(relativeNanos)")
        }
    }
}

///
extension RMBTClient: RMBTTestRunnerDelegate {

    ///
    public func testRunnerDidDetectConnectivity(_ connectivity: RMBTConnectivity) {
        logger.debug("TESTRUNNER: CONNECTIVITY")
    }

    ///
    public func testRunnerDidDetectLocation(_ location: CLLocation) {
        // TODO: do nothing?
    }

    ///
    public func testRunnerDidStartPhase(_ phase: RMBTTestRunnerPhase) {
        //logger.debug("TESTRUNNER: DID START PHASE: \(phase)")
        delegate?.speedMeasurementDidStartPhase(SpeedMeasurementPhase.mapFromRmbtRunnerPhase(phase))
    }

    ///
    public func testRunnerDidFinishPhase(_ phase: RMBTTestRunnerPhase) {
        var result = -1

        switch phase {
        case .latency:
            if let r = testRunner?.medianPingNanos() {
                result = Int(r)
            }
        case .down:
            if let r = testRunner?.downloadKilobitsPerSecond() {
                result = Int(r)
            }
        case .up:
            if let r = testRunner?.uploadKilobitsPerSecond() {
                result = Int(r)
            }
        default:
            break
        }

        delegate?.speedMeasurementDidFinishPhase(SpeedMeasurementPhase.mapFromRmbtRunnerPhase(phase), withResult: result)
        //logger.debug("TESTRUNNER: DID FINISH PHASE: \(phase)")
    }

    ///
    public func testRunnerDidFinishInit(_ time: UInt64) {
        //logger.debug("TESTRUNNER: DID FINISH INIT: \(time)")
    }

    ///
    public func testRunnerDidUpdateProgress(_ progress: Float, inPhase phase: RMBTTestRunnerPhase) {
        //logger.debug("TESTRUNNER: DID UPDATE PROGRESS: \(progress)")
    }

    ///
    public func testRunnerDidMeasureThroughputs(_ throughputs: NSArray, inPhase phase: RMBTTestRunnerPhase) {
        // TODO: use same logic as in android app? (RMBTClient.java:646)

        if let throughputs = throughputs as? [RMBTThroughput], let throughput = throughputs.last { // last?
            let kbps = throughput.kilobitsPerSecond()
            delegate?.speedMeasurementDidMeasureSpeed(Int(kbps), inPhase: SpeedMeasurementPhase.mapFromRmbtRunnerPhase(phase))
        }
    }

    ///
    public func testRunnerDidCompleteWithResult(_ uuid: String) {
        stopHardwareUsageTimer() // stop cpu and memory usage timer

        self.resultUuid = uuid

        if RMBTSettings.sharedSettings.nerdModeEnabled && RMBTSettings.sharedSettings.nerdModeQosEnabled {
            startQosMeasurement() // continue with qos measurement
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
        delegate?.qosMeasurementDidStart(self)
    }

    ///
    public func qualityOfServiceTestDidStop(_ test: QualityOfServiceTest) { // TODO: what is stop, when is it executed? is this necessary?
        delegate?.measurementDidFail(self, withReason: .unknownError) // TODO: better errors
    }

    ///
    public func qualityOfServiceTest(_ test: QualityOfServiceTest, didFinishWithResults results: [QOSTestResult]) {
        // TODO: stop location tracker!

        finishMeasurement()
    }

    ///
    public func qualityOfServiceTest(_ test: QualityOfServiceTest, didFailWithError: NSError!) {
        _running = false

        delegate?.measurementDidFail(self, withReason: .unknownError) // TODO: better errors
    }

    ///
    public func qualityOfServiceTest(_ test: QualityOfServiceTest, didFetchTestTypes testTypes: [QosMeasurementType]) {
        //logger.debug("QOS: DID FETCH TYPES: \(time)")
        delegate?.qosMeasurementList(self, list: testTypes)
    }

    ///
    public func qualityOfServiceTest(_ test: QualityOfServiceTest, didFinishTestType testType: QosMeasurementType) {
        //logger.debug("QOS: DID FINISH TYPE: \(time)")
        self.delegate?.qosMeasurementFinished(self, type: testType)
    }

    ///
    public func qualityOfServiceTest(_ test: QualityOfServiceTest, didProgressToValue progress: Float) {
        delegate?.qosMeasurementDidUpdateProgress(self, progress: progress)
    }

}

// MARK: ControlServer proxy methods

///
extension RMBTClient {

    ///
    public class func refreshSettings() {
        MeasurementHistory.sharedMeasurementHistory.dirty = true // set history to dirty for changed control servers
        ControlServer.sharedControlServer.updateWithCurrentSettings()
    }

    ///
    public class var uuid: String? {
        get {
            return ControlServer.sharedControlServer.uuid
        }
    }

    ///
    public class var controlServerVersion: String? {
        get {
            return ControlServer.sharedControlServer.version
        }
    }

}
