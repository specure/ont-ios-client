//
//  QOSTracerouteTest.swift
//  RMBT
//
//  Created by Benjamin Pucher on 05.12.14.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

import Foundation

///
class QOSTracerouteTest: QOSTest {

    private let PARAM_HOST = "host"
    private let PARAM_MAX_HOPS = "max_hops"

    //

    var host: String?
    var maxHops: UInt8 = 64

    /// config values not configured on server
    var noResponseTimeout: NSTimeInterval = 1 // x seconds
    var bytesPerPackage: UInt16 = 72 // 72 bytes
    var triesPerTTL: UInt8 = 1 // x tries per ttl
    ///

    //

    ///
    override var description: String {
        return super.description + ", [host: \(host), maxHops: \(maxHops), noResponseTimeout: \(noResponseTimeout), bytesPerPackage: \(bytesPerPackage), triesPerTTL: \(triesPerTTL)]"
    }

    //

    ///
    override init(testParameters: QOSTestParameters) {
        if let host = testParameters[PARAM_HOST] as? String {
            // TODO: length check on host?
            self.host = host
        }

        // max hops
        if let maxHopsString = testParameters[PARAM_MAX_HOPS] as? String {
            if let maxHops = UInt8(maxHopsString) {
                self.maxHops = maxHops
            }
        }

        super.init(testParameters: testParameters)
    }

    ///
    override func getType() -> QOSTestType! {
        return .TRACEROUTE
    }
}
