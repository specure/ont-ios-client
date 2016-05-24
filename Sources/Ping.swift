//
//  Ping.swift
//  RMBTClient
//
//  Created by Benjamin Pucher on 28.03.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
class Ping: CustomStringConvertible {

    ///
    let serverNanos: UInt64

    ///
    let clientNanos: UInt64

    /// relative to test start
    let relativeTimestampNanos: UInt64

    //

    ///
    init(serverNanos: UInt64, clientNanos: UInt64, relativeTimestampNanos timestampNanos: UInt64) {
        self.serverNanos = serverNanos
        self.clientNanos = clientNanos
        self.relativeTimestampNanos = timestampNanos
    }

    ///
    func testResultDictionary() -> [String: NSNumber] {
        return [
            "value_server": NSNumber(unsignedLongLong: serverNanos),
            "value":        NSNumber(unsignedLongLong: clientNanos),
            "time_ns":      NSNumber(unsignedLongLong: relativeTimestampNanos)
        ]
    }

    ///
    var description: String {
        //return String(format: "RMBTPing (server=%" PRIu64 ", client=%" PRIu64 ")", serverNanos, clientNanos)
        return "RMBTPing  (server = \(serverNanos), client = \(clientNanos))"
    }
}
