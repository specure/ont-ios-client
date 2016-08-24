//
//  IpResponse.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 23.08.16.
//
//

import Foundation
import ObjectMapper

///
public class IpResponse: BasicResponse {

    ///
    var ip: String = ""

    ///
    var version: String = ""

    ///
    override public func mapping(map: Map) {
        super.mapping(map)

        ip <- map["ip"]
        version <- map["version"]
    }

    override public var description: String {
        return "ip: \(ip), version: \(version)"
    }
}
