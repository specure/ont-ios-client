//
//  RMBTClient.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 21.06.16.
//
//

import Foundation
import CoreLocation

///
public enum SpeedMeasurementPhase: Int {
    case None = 0
    case FetchingTestParams
    case Wait
    case Init
    case Latency
    case Down
    case InitUp
    case Up
    case SubmittingTestResult

    ///
    public static func mapFromRmbtRunnerPhase(phase: RMBTTestRunnerPhase) -> SpeedMeasurementPhase { // TODO: improve
        return SpeedMeasurementPhase.init(rawValue: phase.rawValue)!
    }
}

///
public enum RMBTClientCancelReason: Int {
    case UnknownError = 0
    case UserRequested
    case AppBackgrounded

    case NoConnection
    case MixedConnectivity

    case ErrorFetchingSpeedMeasurementParams
    case ErrorSubmittingSpeedMeasurement

    case ErrorFetchingQosMeasurementParams
    case ErrorSubmittingQosMeasurement

    ///
    public static func mapFromSpeedMesurementCancelReason(cancelReason: RMBTTestRunnerCancelReason) -> RMBTClientCancelReason { // TODO: improve
        switch cancelReason {
        case .UserRequested:
            return .UserRequested
        case .AppBackgrounded:
            return .AppBackgrounded
        case .MixedConnectivity:
            return .MixedConnectivity
        case .NoConnection:
            return .NoConnection
        case .ErrorFetchingTestingParams:
            return .ErrorFetchingSpeedMeasurementParams
        case .ErrorSubmittingTestResult:
            return .ErrorSubmittingSpeedMeasurement
        }
    }
}

///
public protocol RMBTClientDelegate {

    ///
    //func measurementDidStart(client: RMBTClient)

    ///
    func measurementDidComplete(client: RMBTClient)

    ///
    func measurementDidFail(client: RMBTClient, withReason reason: RMBTClientCancelReason)

// MARK: Speed

    ///
    func speedMeasurementDidMeasureSpeed(kbps: Int, inPhase phase: SpeedMeasurementPhase)

    ///
    func speedMeasurementDidStartPhase(phase: SpeedMeasurementPhase)

    ///
    func speedMeasurementDidFinishPhase(phase: SpeedMeasurementPhase, withResult result: Int)

// MARK: Qos

    ///
    func qosMeasurementDidStart(client: RMBTClient)

    ///
    func qosMeasurementDidUpdateProgress(client: RMBTClient, progress: Float)
}

/////////////

///
public class RMBTClient {

    ///
    private var testRunner: RMBTTestRunner?

    ///
    private var qualityOfServiceTestRunner: QualityOfServiceTest?

    ///
    public var delegate: RMBTClientDelegate?

    ///
    public var running: Bool {
        get {
            return _running
        }
    }

    ///
    private var _running = false

    /// used for updating cpu and memory usage
    private var hardwareUsageTimer: NSTimer?

    ///
    private let cpuMonitor = RMBTCPUMonitor()

    ///
    private let ramMonitor = RMBTRAMMonitor()

    ///
    public init() {

    }

    ///
    public func startMeasurement() {
        // TODO: hardware timer etc

        startSpeedMeasurement()
    }

    ///
    public func stopMeasurement() {
        testRunner?.cancel()
        qualityOfServiceTestRunner?.stop()

        _running = false
    }

    ///
    private func startSpeedMeasurement() {
        testRunner = RMBTTestRunner(delegate: self)
        testRunner?.start()

        _running = true

        startHardwareUsageTimer() // start cpu and memory usage timer
    }

    ///
    private func startQosMeasurement() {
        if let testToken = testRunner?.testParams.testToken,
               measurementUuid = testRunner?.testParams.testUuid,
               testStartNanos = testRunner?.testStartNanos() {

            qualityOfServiceTestRunner = QualityOfServiceTest(testToken: testToken, measurementUuid: measurementUuid, speedtestStartTime: testStartNanos)

            qualityOfServiceTestRunner?.delegate = self

            qualityOfServiceTestRunner?.start()
        }
    }

// MARK: Hardware usage timer

    ///
    func startHardwareUsageTimer() {
        hardwareUsageTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(hardwareUsageTimerFired), userInfo: nil, repeats: true)
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

            if let cpuUsage = cpuMonitor.getCPUUsage() as? [NSNumber] where cpuUsage.count > 0 {
                testRunner?.addCpuUsage(cpuUsage[0].doubleValue, atNanos: Int(relativeNanos))

                logger.debug("ADDING CPU USAGE: \(cpuUsage[0].floatValue) atNanos: \(relativeNanos)")
            } else {
                // TODO: else write implausible error, or use previous value
            }

            //////////////////
            // RAM

            let ramUsagePercentFree = ramMonitor.getRAMUsagePercentFree()

            testRunner?.addMemoryUsage(Double(ramUsagePercentFree), atNanos: Int(relativeNanos))
            logger.debug("ADDING RAM USAGE: \(ramUsagePercentFree) atNanos: \(relativeNanos)")
        }
    }
}

///
extension RMBTClient: RMBTTestRunnerDelegate {

    ///
    public func testRunnerDidDetectConnectivity(connectivity: RMBTConnectivity) {
        logger.debug("TESTRUNNER: CONNECTIVITY")
    }

    ///
    public func testRunnerDidDetectLocation(location: CLLocation) {
        // TODO: do nothing?
    }

    ///
    public func testRunnerDidStartPhase(phase: RMBTTestRunnerPhase) {
        //logger.debug("TESTRUNNER: DID START PHASE: \(phase)")
        delegate?.speedMeasurementDidStartPhase(SpeedMeasurementPhase.mapFromRmbtRunnerPhase(phase))
    }

    ///
    public func testRunnerDidFinishPhase(phase: RMBTTestRunnerPhase) {
        var result = -1

        switch phase {
        case .Latency:
            if let r = testRunner?.medianPingNanos() {
                result = Int(r)
            }
        case .Down:
            if let r = testRunner?.downloadKilobitsPerSecond() {
                result = Int(r)
            }
        case .Up:
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
    public func testRunnerDidFinishInit(time: UInt64) {
        //logger.debug("TESTRUNNER: DID FINISH INIT: \(time)")
    }

    ///
    public func testRunnerDidUpdateProgress(progress: Float, inPhase phase: RMBTTestRunnerPhase) {
        //logger.debug("TESTRUNNER: DID UPDATE PROGRESS: \(progress)")
    }

    ///
    public func testRunnerDidMeasureThroughputs(throughputs: NSArray, inPhase phase: RMBTTestRunnerPhase) {
        // TODO: use same logic as in android app? (RMBTClient.java:646)

        if let throughputs = throughputs as? [RMBTThroughput], throughput = throughputs.last { // last?
            let kbps = throughput.kilobitsPerSecond()
            delegate?.speedMeasurementDidMeasureSpeed(Int(kbps), inPhase: SpeedMeasurementPhase.mapFromRmbtRunnerPhase(phase))
        }
    }

    ///
    public func testRunnerDidCompleteWithResult(result: RMBTHistoryResult) {
        stopHardwareUsageTimer() // stop cpu and memory usage timer

        startQosMeasurement() // continue with qos measurement
    }

    ///
    public func testRunnerDidCancelTestWithReason(cancelReason: RMBTTestRunnerCancelReason) {
        stopHardwareUsageTimer() // stop cpu and memory usage timer

        _running = false

        let reason = RMBTClientCancelReason.mapFromSpeedMesurementCancelReason(cancelReason)

        delegate?.measurementDidFail(self, withReason: reason)
    }

}

///
extension RMBTClient: QualityOfServiceTestDelegate {

    ///
    public func qualityOfServiceTestDidStart(test: QualityOfServiceTest) {
        delegate?.qosMeasurementDidStart(self)
    }

    ///
    public func qualityOfServiceTestDidStop(test: QualityOfServiceTest) { // TODO: what is stop, when is it executed? is this necessary?
        delegate?.measurementDidFail(self, withReason: .UnknownError) // TODO: better errors
    }

    ///
    public func qualityOfServiceTest(test: QualityOfServiceTest, didFinishWithResults results: [QOSTestResult]) {
        _running = false

        delegate?.measurementDidComplete(self)
    }

    ///
    public func qualityOfServiceTest(test: QualityOfServiceTest, didFailWithError: NSError!) {
        _running = false

        delegate?.measurementDidFail(self, withReason: .UnknownError) // TODO: better errors
    }

    ///
    public func qualityOfServiceTest(test: QualityOfServiceTest, didFetchTestTypes testTypes: [QOSTestType]) {
        //logger.debug("QOS: DID FETCH TYPES: \(time)")
    }

    ///
    public func qualityOfServiceTest(test: QualityOfServiceTest, didFinishTestType testType: QOSTestType) {
        //logger.debug("QOS: DID FINISH TYPE: \(time)")
    }

    ///
    public func qualityOfServiceTest(test: QualityOfServiceTest, didProgressToValue progress: Float) {
        delegate?.qosMeasurementDidUpdateProgress(self, progress: progress)
    }

}
