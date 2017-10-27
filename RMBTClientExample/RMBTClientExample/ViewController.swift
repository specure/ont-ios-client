//
//  ViewController.swift
//  RMBTClientExample
//
//  Created by Tomas Baculák on 24/10/2017.
//  Copyright © 2017 Vanya Otvorij. All rights reserved.
//

import UIKit
import RMBTClient

class ViewController: UIViewController {
    
    //
    @IBOutlet var manageMeasurementButton:UIButton!
    //
    @IBOutlet var downloadResultLabel:UILabel!
    //
    @IBOutlet var uploadResultLabel:UILabel!
    //
    @IBOutlet var jitterResultLabel:UILabel!
    //
    @IBOutlet var packeLossResultLabel:UILabel!
    //
    @IBOutlet var pingResultLabel:UILabel!
    //
    let client = RMBTClient()

    //
    @IBAction func manageMeasurement(_ sender: UIButton) {
        
        cleanResultLabels()
        
        manageMeasurementButton.isSelected ? client.stopMeasurement():client.startMeasurement()
        manageMeasurementButton.isSelected = !manageMeasurementButton.isSelected
        makeManageMeasurementButton(available:false)
    }
    
    //
    override func viewDidLoad() {
        
        client.delegate = self
        client.clientType = .standard
        
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        cleanResultLabels()
    }
    
    private func cleanResultLabels() {
        downloadResultLabel.text = "-"
        uploadResultLabel.text = "-"
        jitterResultLabel.text = "-"
        packeLossResultLabel.text = "-"
        pingResultLabel.text = "-"
    }
    
    internal func makeManageMeasurementButton(available:Bool) {
        manageMeasurementButton.isUserInteractionEnabled = available
    }
}

extension ViewController: RMBTClientDelegate {
    // not deployed
    func measurementDidStart(client: RMBTClient) {
        
    }
    //
    func measurementDidCompleteVoip(_ client: RMBTClient, withResult: [String : Any]) {
        
        // compute mean jitter as outcome
        if let inJiter = withResult["voip_result_out_mean_jitter"] as? NSNumber,
            let outJiter = withResult["voip_result_in_mean_jitter"] as? NSNumber {
            
            // assign value
            self.jitterResultLabel?.text = String(format:"%.2f",(inJiter.doubleValue + outJiter.doubleValue)/2_000_000)
        }
        
        // compute packet loss (both directions) as outcome
        if let inPL = withResult["voip_result_in_num_packets"] as? NSNumber,
            let outPL = withResult["voip_result_out_num_packets"] as? NSNumber,
            let objDelay = withResult["voip_objective_delay"] as? NSNumber,
            let objCallDuration = withResult["voip_objective_call_duration"] as? NSNumber,
            objDelay != 0,
            objCallDuration != 0 {
            
            let total = objCallDuration.decimalValue/objDelay.decimalValue
            
            let packetLossUp = (total-outPL.decimalValue)/total
            let packetLossDown = (total-inPL.decimalValue)/total

            self.packeLossResultLabel?.text = String(describing: ((packetLossUp+packetLossDown)/2)*100)
        }
    }
    //
    func measurementDidComplete(_ client: RMBTClient, withResult result: String) {
        manageMeasurementButton.isSelected = false
        makeManageMeasurementButton(available:true)
    }
    //
    func measurementDidFail(_ client: RMBTClient, withReason reason: RMBTClientCancelReason) {
        makeManageMeasurementButton(available:true)
    }
    //
    func speedMeasurementDidUpdateWith(progress: Float, inPhase phase: SpeedMeasurementPhase) {
        
    }
    //
    func speedMeasurementDidMeasureSpeed(throughputs: [RMBTThroughput], inPhase phase: SpeedMeasurementPhase) {
        
        var kbps: UInt32 = 0
        
        //logger.debug("THROUGHPUTS COUNT: \(throughputs.count)")
        
        for i in 0 ..< throughputs.count {
            let t = throughputs[i]
            kbps = t.kilobitsPerSecond()
            
            if i == 0 {
                switch phase {
                case .down: self.downloadResultLabel?.text = RMBTSpeedMbpsString(Int(kbps), withMbps: false)
                case .up: self.uploadResultLabel?.text = RMBTSpeedMbpsString(Int(kbps), withMbps: false)
                default:
                    break
                }
            }
        }
    }
    //
    func speedMeasurementDidStartPhase(_ phase: SpeedMeasurementPhase) {
        
        if phase == .Init {
            makeManageMeasurementButton(available:true)
        }
    }
    //
    func speedMeasurementDidFinishPhase(_ phase: SpeedMeasurementPhase, withResult result: Int) {
        
        switch phase {
        case .down: downloadResultLabel.text = RMBTSpeedMbpsString(result, withMbps: false)
        case .up: uploadResultLabel.text = RMBTSpeedMbpsString(result, withMbps: false)
        case .latency: pingResultLabel.text = RMBTMillisecondsString(UInt64(result))
        default:
            break
        }
    }
    
    // QoS Not implemented in the example yet
    func qosMeasurementDidStart(_ client: RMBTClient) {
        
    }
    //
    func qosMeasurementDidUpdateProgress(_ client: RMBTClient, progress: Float) {
        
    }
    //
    func qosMeasurementList(_ client: RMBTClient, list: [QosMeasurementType]) {
        
    }
    //
    func qosMeasurementFinished(_ client: RMBTClient, type: QosMeasurementType) {
        
    }
}

