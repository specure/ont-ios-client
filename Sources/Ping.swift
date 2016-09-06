//
//  Ping.swift
//  RMBTClient
//
//  Created by Benjamin Pucher on 28.03.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation
import ObjectMapper

///
public class Ping: Mappable, CustomStringConvertible {

    ///
    var serverNanos: UInt64?

    ///
    var clientNanos: UInt64?

    /// relative to test start
    var relativeTimestampNanos: UInt64?

    //

    ///
    init(serverNanos: UInt64, clientNanos: UInt64, relativeTimestampNanos timestampNanos: UInt64) {
        self.serverNanos = serverNanos
        self.clientNanos = clientNanos
        self.relativeTimestampNanos = timestampNanos
    }

    ///
    required public init?(_ map: Map) {

    }

    ///
    public func mapping(map: Map) {
        serverNanos             <- (map["value_server"], UInt64NSNumberTransformOf)
        clientNanos             <- (map["value"], UInt64NSNumberTransformOf)
        relativeTimestampNanos  <- (map["relative_time_ns"], UInt64NSNumberTransformOf)
    }

    ///
    public var description: String {
        //return String(format: "RMBTPing (server=%" PRIu64 ", client=%" PRIu64 ")", serverNanos, clientNanos)
        return "RMBTPing  (server = \(serverNanos), client = \(clientNanos))"
    }
}
