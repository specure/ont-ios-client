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
    var serverNanos: Int?

    ///
    var clientNanos: Int?

    /// relative to test start
    var relativeTimestampNanos: Int?

    //

    ///
    init(serverNanos: UInt64, clientNanos: UInt64, relativeTimestampNanos timestampNanos: UInt64) {
        self.serverNanos = Int(serverNanos)
        self.clientNanos = Int(clientNanos)
        self.relativeTimestampNanos = Int(timestampNanos)
    }
    
    ///
    required public init?(_ map: Map) {
        
    }
    
    ///
    public func mapping(map: Map) {
        serverNanos             <- map["value_server"]
        clientNanos             <- map["value"]
        relativeTimestampNanos  <- map["relative_time_ns"]
    }

    ///
    public var description: String {
        //return String(format: "RMBTPing (server=%" PRIu64 ", client=%" PRIu64 ")", serverNanos, clientNanos)
        return "RMBTPing  (server = \(serverNanos), client = \(clientNanos))"
    }
}
