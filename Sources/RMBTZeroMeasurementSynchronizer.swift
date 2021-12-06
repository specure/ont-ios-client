//
//  RMBTZeroMeasurementSynchronizer.swift
//  Pods
//
//  Created by Sergey Glushchenko on 10/4/17.
//

import Alamofire

open class RMBTZeroMeasurementSynchronizer: NSObject {
    public static let shared = RMBTZeroMeasurementSynchronizer()
    
    var timer: Timer?
    
    private let worker = DispatchQueue(label: "RMBTZeroMeasurementSynchronizer worker")
    private let duration: TimeInterval = 60.0 //seconds
    
    private var isSynchronizating = false
    
    private var reachabilityManager = NetworkReachabilityManager()
    
    deinit {
        defer {
            if timer?.isValid == true {
                timer?.invalidate()
            }
        }
    }
    override init() {
        super.init()
    }
    
    open func startSynchronization() {
        if timer?.isValid == true {
            timer?.invalidate()
        }
        
        reachabilityManager?.startListening(onUpdatePerforming: { [weak self] (status) in
            guard let self = self else { return }
            
            if (status != .notReachable) {
                self.tick(timer: self.timer)
            }
        })

        
        timer = Timer.scheduledTimer(timeInterval: self.duration, target: self, selector: #selector(tick(timer:)), userInfo: nil, repeats: true)
        self.tick(timer: timer)
    }
    
    open func stopSynchronization() {
        if timer?.isValid == true {
            timer?.invalidate()
        }
        
        reachabilityManager?.stopListening()
    }

    @objc func tick(timer: Timer?) {
        if (isSynchronizating == false) {
            self.isSynchronizating = true
            if let zeroMeasurements = StoredZeroMeasurement.loadObjects() {
                var measurements: [ZeroMeasurementRequest] = []
                var measurementsForDelete: [StoredZeroMeasurement] = []
                for zeroMeasurement in zeroMeasurements {
                    if let _ = zeroMeasurement.speedMeasurementResult() {
                        measurements.append(ZeroMeasurementRequest(measurement: zeroMeasurement))
                    }
                    else {
                        measurementsForDelete.append(zeroMeasurement)
                    }
                }
                
                if measurements.count > 0 {
                    ZeroMeasurementRequest.submit(zeroMeasurements: measurements, success: { [weak self] (response) in
                        DispatchQueue.main.async {
                            for measurement in zeroMeasurements {
                                measurement.deleteObject()
                            }
                            self?.isSynchronizating = false
                            self?.tick(timer: self?.timer)
                        }
                    }, error: { [weak self] (error) in
                        self?.isSynchronizating = false
                    })
                }
                else {
                    if measurementsForDelete.count > 0 {
                        DispatchQueue.main.async {
                            for measurement in measurementsForDelete {
                                measurement.deleteObject()
                                self.isSynchronizating = false
                                DispatchQueue.main.async {
                                    self.tick(timer: self.timer)
                                }
                            }
                        }
                    }
                    else {
                        self.isSynchronizating = false
                    }
                }
            }
            else {
                self.isSynchronizating = true
            }
        }
    }
    
}
