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
    //func qosMeasurementDidStart(client: RMBTClient)
    
    ///
    //func qosMeasurementDidStop(client: RMBTClient)
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
    public init() {
    
    }
    
    ///
    public func startMeasurement() {
        // TODO: hardware timer etc
        
        startSpeedMeasurement()
    }

    ///
    public func stopMeasurement() {
    
    }
    
    ///
    private func startSpeedMeasurement() {
        testRunner = RMBTTestRunner(delegate: self)
        testRunner?.start()
    }
    
    ///
    private func startQosMeasurement() {
        qualityOfServiceTestRunner = QualityOfServiceTest(testToken: "", measurementUuid: "", speedtestStartTime: 1000) // TODO
        
        qualityOfServiceTestRunner?.delegate = self
        
        qualityOfServiceTestRunner?.start()
    }
}

///
extension RMBTClient: RMBTTestRunnerDelegate {
    
    ///
    public func testRunnerDidDetectConnectivity(connectivity: RMBTConnectivity) {
        //logger.debug("TESTRUNNER: CONNECTIVITY")
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
            if let r = testRunner?.testResult.medianPingNanos {
                result = Int(r)
            }
        case .Down:
            if let r = testRunner?.testResult.totalDownloadHistory.totalThroughput.kilobitsPerSecond() {
                result = Int(r)
            }
        case .Up:
            if let r = testRunner?.testResult.totalUploadHistory.totalThroughput.kilobitsPerSecond() {
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
        
        if let throughputs = throughputs as? [RMBTThroughput] {
            if let throughput = throughputs.last { // last?
                let kbps = throughput.kilobitsPerSecond()
                delegate?.speedMeasurementDidMeasureSpeed(Int(kbps), inPhase: SpeedMeasurementPhase.mapFromRmbtRunnerPhase(phase))
            }
        }
    }
    
    ///
    public func testRunnerDidCompleteWithResult(result: RMBTHistoryResult) {
        // TODO: stop hardware timer
        
        //startQosMeasurement() // TODO
        delegate?.measurementDidComplete(self)
    }
    
    ///
    public func testRunnerDidCancelTestWithReason(cancelReason: RMBTTestRunnerCancelReason) {
        // TODO: stop hardware timer
        
        let reason = RMBTClientCancelReason.mapFromSpeedMesurementCancelReason(cancelReason)
        
        delegate?.measurementDidFail(self, withReason: reason)
    }

}

///
extension RMBTClient: QualityOfServiceTestDelegate {
    
    ///
    public func qualityOfServiceTestDidStart(test: QualityOfServiceTest) {

    }
    
    ///
    public func qualityOfServiceTestDidStop(test: QualityOfServiceTest) { // TODO: what is stop, when is it executed? is this necessary?
        delegate?.measurementDidFail(self, withReason: .UnknownError) // TODO: better errors
    }
    
    ///
    public func qualityOfServiceTest(test: QualityOfServiceTest, didFinishWithResults results: [QOSTestResult]) {
        delegate?.measurementDidComplete(self)
    }
    
    ///
    public func qualityOfServiceTest(test: QualityOfServiceTest, didFailWithError: NSError!) {
        delegate?.measurementDidFail(self, withReason: .UnknownError) // TODO: better errors
    }
    
    ///
    public func qualityOfServiceTest(test: QualityOfServiceTest, didFetchTestTypes testTypes: [QOSTestType]) {

    }
    
    ///
    public func qualityOfServiceTest(test: QualityOfServiceTest, didFinishTestType testType: QOSTestType) {

    }
    
    ///
    public func qualityOfServiceTest(test: QualityOfServiceTest, didProgressToValue: Float) {

    }
    
}
