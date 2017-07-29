//
//  ONTClient.swift
//  rmbt-ios-client
//
//  Created by Tomas Baculák on 04/04/2017.
//
//

import Foundation
import CoreLocation

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
public enum ONTSpeedMeasurementPhase: Int {
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
    public static func mapFromOntRunnerPhase(_ phase: ONTTestRunnerPhase) -> ONTSpeedMeasurementPhase { // TODO: improve
        return ONTSpeedMeasurementPhase.init(rawValue: phase.rawValue)!
    }
}


///
public protocol ONTClientDelegate {
    
    ///
    //func measurementDidStart(client: RMBTClient)
    
    ///
    func measurementDidComplete(_ client: ONTClient, withResult result: String)
    
    ///
    func measurementDidFail(_ client: ONTClient, withReason reason: RMBTClientCancelReason)
    
    // MARK: Speed
    
    ///
    func speedMeasurementDidMeasureSpeed(_ kbps: Int, inPhase phase: ONTSpeedMeasurementPhase)
    
    ///
    func speedMeasurementDidStartPhase(_ phase: ONTSpeedMeasurementPhase)
    
    ///
    func speedMeasurementDidFinishPhase(_ phase: ONTSpeedMeasurementPhase, withResult result: Int)
    

}

/////////////

///
open class ONTClient {
    
    ///
    internal var testRunner: ONTTestRunner?
    
    ///
    internal var qualityOfServiceTestRunner: QualityOfServiceTest?
    
    ///
    open var delegate: ONTClientDelegate?
    
    ///
    internal var resultUuid: String?
    
    ///
    open var running: Bool {
        get {
            return _running
        }
    }
    
    ///
    internal var _running = false
    
    /// used for updating cpu and memory usage
    internal var hardwareUsageTimer: Timer?
    
    ///
    internal let cpuMonitor = RMBTCPUMonitor()
    
    ///
    internal let ramMonitor = RMBTRAMMonitor()
    
    ///
    public init() {
        
    }
    
    ///
    open func startMeasurement() {
        testRunner = ONTTestRunner(delegate: self)
        testRunner?.start()
        
        _running = true
        
        // startHardwareUsageTimer() // start cpu and memory usage timer // NO need for NKOM
    }
    
    ///
    open func stopMeasurement() {
        testRunner?.cancel()
        qualityOfServiceTestRunner?.stop()
        
        _running = false
    }
    
    ///
    internal func finishMeasurement() {
        _running = false
        
        if let uuid = self.resultUuid {
            MeasurementHistory.sharedMeasurementHistory.dirty = true // set history to dirty after measurement
            
            delegate?.measurementDidComplete(self, withResult: uuid)
        } else {
            delegate?.measurementDidFail(self, withReason: .unknownError) // TODO better error handling (but this error should never happen...)
        }
    }
    
    // MARK: Hardware usage timer
    
    ///
    func startHardwareUsageTimer() {
        hardwareUsageTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(hardwareUsageTimerFired), userInfo: nil, repeats: true)
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
extension ONTClient: ONTTestRunnerDelegate {
    ///
    
    ///
    public func testRunnerDidDetectConnectivity(_ connectivity: RMBTConnectivity) {
        logger.debug("TESTRUNNER: CONNECTIVITY")
    }
    
    ///
    public func testRunnerDidDetectLocation(_ location: CLLocation) {
        // TODO: do nothing?
    }
    
    ///
    public func testRunnerDidStartPhase(_ phase: ONTTestRunnerPhase) {
        //logger.debug("TESTRUNNER: DID START PHASE: \(phase)")
        delegate?.speedMeasurementDidStartPhase(ONTSpeedMeasurementPhase.mapFromOntRunnerPhase(phase))
    }
    
    ///
    public func testRunnerDidFinishPhase(_ phase: ONTTestRunnerPhase) {
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
        
        delegate?.speedMeasurementDidFinishPhase(ONTSpeedMeasurementPhase.mapFromOntRunnerPhase(phase), withResult: result)
        //logger.debug("TESTRUNNER: DID FINISH PHASE: \(phase)")
    }
    
    ///
    public func testRunnerDidFinishInit(_ time: UInt64) {
        //logger.debug("TESTRUNNER: DID FINISH INIT: \(time)")
    }
    
    ///
    public func testRunnerDidUpdateProgress(_ progress: Float, inPhase phase: ONTTestRunnerPhase) {
        //logger.debug("TESTRUNNER: DID UPDATE PROGRESS: \(progress)")
    }
    
    ///
    public func testRunnerDidMeasureThroughputs(_ throughputs: NSArray, inPhase phase: ONTTestRunnerPhase) {
        // TODO: use same logic as in android app? (RMBTClient.java:646)
        
        if let throughputs = throughputs as? [RMBTThroughput], let throughput = throughputs.last { // last?
            let kbps = throughput.kilobitsPerSecond()
            delegate?.speedMeasurementDidMeasureSpeed(Int(kbps), inPhase: ONTSpeedMeasurementPhase.mapFromOntRunnerPhase(phase))
        }
    }
    
    ///
    public func testRunnerDidCompleteWithResult(_ uuid: String) {
        stopHardwareUsageTimer() // stop cpu and memory usage timer
        
        self.resultUuid = uuid
        finishMeasurement()
    }
    
    ///
    public func testRunnerDidCancelTestWithReason(_ cancelReason: RMBTTestRunnerCancelReason) {
        stopHardwareUsageTimer() // stop cpu and memory usage timer
        
        _running = false
        
        let reason = RMBTClientCancelReason.mapFromSpeedMesurementCancelReason(cancelReason)
        
        delegate?.measurementDidFail(self, withReason: reason)
    }
    
}

// MARK: ControlServer proxy methods

///
extension ONTClient {
    
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
