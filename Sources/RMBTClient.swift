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
public enum MeasurementPhase: String {
    case INIT = "init"
    

}

///
public protocol RMBTClientDelegate {
    
    ///
    //func measurementDidStart(client: RMBTClient)
    
    ///
    func measurementDidStop(client: RMBTClient)
    
    ///
    //func measurementDidFail(client: RMBTClient)
    
// MARK: Speed
    
    
    
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

    }
    
    ///
    public func testRunnerDidDetectLocation(location: CLLocation) {

    }
    
    ///
    public func testRunnerDidStartPhase(phase: RMBTTestRunnerPhase) {

    }
    
    ///
    public func testRunnerDidFinishPhase(phase: RMBTTestRunnerPhase) {
        
    }
    
    ///
    public func testRunnerDidFinishInit(time: UInt64) {
       
    }
    
    ///
    public func testRunnerDidUpdateProgress(progress: Float, inPhase phase: RMBTTestRunnerPhase) {
        
    }
    
    ///
    public func testRunnerDidMeasureThroughputs(throughputs: NSArray, inPhase phase: RMBTTestRunnerPhase) {
        
    }
    
    ///
    public func testRunnerDidCompleteWithResult(result: RMBTHistoryResult) {
        //startQosMeasurement() // TODO
        delegate?.measurementDidStop(self)
    }
    
    ///
    public func testRunnerDidCancelTestWithReason(cancelReason: RMBTTestRunnerCancelReason) {
        delegate?.measurementDidStop(self) // TODO: other delegate call!
    }

}

///
extension RMBTClient: QualityOfServiceTestDelegate {
    
    ///
    public func qualityOfServiceTestDidStart(test: QualityOfServiceTest) {

    }
    
    ///
    public func qualityOfServiceTestDidStop(test: QualityOfServiceTest) {
        delegate?.measurementDidStop(self)
    }
    
    ///
    public func qualityOfServiceTest(test: QualityOfServiceTest, didFinishWithResults results: [QOSTestResult]) {

    }
    
    ///
    public func qualityOfServiceTest(test: QualityOfServiceTest, didFailWithError: NSError!) {

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
