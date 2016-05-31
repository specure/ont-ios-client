//
//  Speed.swift
//  RMBTClient
//
//  Created by Benjamin Pucher on 02.04.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

let GAUGE_PARTS = 4.25
let LOG10_MAX = log10(250.0)

///
public func RMBTSpeedLogValue(kbps: UInt32) -> Double {
    let bps = UInt64(kbps * 1_000)
    var log: Double

    if bps < 10_000 {
        log = 0
    } else {
        log = ((GAUGE_PARTS - LOG10_MAX) + log10(Double(bps) / Double(1e6))) / GAUGE_PARTS
    }

    //if (log > 1.0) {
    //    log = 1.0
    //}

    return log
}

///
public func RMBTSpeedMbpsString(kbps: UInt32) -> String {
    let localizedMps = NSLocalizedString("test.speed.unit", value: "Mbps", comment: "Speed suffix")

    return String(format: "%@ %@", RMBTFormatNumber(NSNumber(double: Double(kbps) / 1000.0)), localizedMps)
}
