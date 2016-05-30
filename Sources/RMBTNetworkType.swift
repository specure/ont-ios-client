//
//  RMBTNetworkType.swift
//  RMBT
//
//  Created by Benjamin Pucher on 21.09.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
public enum RMBTNetworkType: Int {
    case Unknown = -1
    case None = 0 // Used internally to denote no connection
    case Browser = 98
    case WiFi = 99
    case Cellular = 105
}

///
public func RMBTNetworkTypeMake(code: Int) -> RMBTNetworkType {
    return RMBTNetworkType(rawValue: code) ?? .Unknown
}

///
public func RMBTNetworkTypeIdentifier(networkType: RMBTNetworkType) -> String? {
    switch networkType {
        case .Cellular: return "cellular"
        case .WiFi:     return "wifi"
        case .Browser:  return "browser"
        default:        return nil
    }
}
