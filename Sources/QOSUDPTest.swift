//
//  QOSUDPTest.swift
//  RMBT
//
//  Created by Benjamin Pucher on 05.12.14.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

import Foundation

///
class QOSUDPTest: QOSTest {

    private let PARAM_NUM_PACKETS_OUT = "out_num_packets"
    private let PARAM_NUM_PACKETS_IN = "in_num_packets"

    private let PARAM_PORT_OUT = "out_port"
    private let PARAM_PORT_IN = "in_port"

    private let PARAM_DELAY = "delay"

    //

    var packetCountOut: UInt16?
    var packetCountIn: UInt16?

    var portOut: UInt16?
    var portIn: UInt16?

    var delay: UInt64 = 300_000_000 // 300 ms

    //

    ///
    override var description: String {
        return super.description + ", [packetCountOut: \(packetCountOut), packetCountIn: \(packetCountIn), portOut: \(portOut), portIn: \(portIn), delay: \(delay)]"
    }

    //

    ///
    override init(testParameters: QOSTestParameters) {
        // packetCountOut
        if let packetCountOutString = testParameters[PARAM_NUM_PACKETS_OUT] as? String {
            if let packetCountOut = UInt16(packetCountOutString) {
                self.packetCountOut = packetCountOut
            }
        }

        // packetCountIn
        if let packetCountInString = testParameters[PARAM_NUM_PACKETS_IN] as? String {
            if let packetCountIn = UInt16(packetCountInString) {
                self.packetCountIn = packetCountIn
            }
        }

        // portOut
        if let portOutString = testParameters[PARAM_PORT_OUT] as? String {
            if let portOut = UInt16(portOutString) {
                self.portOut = portOut
            }
        }

        // portIn
        if let portInString = testParameters[PARAM_PORT_IN] as? String {
            if let portIn = UInt16(portInString) {
                self.portIn = portIn
            }
        }

        // delay
        if let delayString = testParameters[PARAM_DELAY] as? NSString {
            let delay = delayString.longLongValue
            if delay > 0 {
                self.delay = UInt64(delay)
            }
        }

        super.init(testParameters: testParameters)
    }

    ///
    override func getType() -> QOSMeasurementType! {
        return .UDP
    }

}
