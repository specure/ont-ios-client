//
//  TrafficClassification.swift
//  RMBT
//
//  Created by Benjamin Pucher on 03.02.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
public enum TrafficClassification: String {
    case UNKNOWN = "unknown" // = nil
    case NONE = "none" // = 0..1249
    case LOW = "low" // = 1250..12499
    case MID = "mid" // = 12500..124999
    case HIGH = "high" // = 125000..UInt64.max

    ///
    public static func classifyBytesPerSecond(bytesPerSecond: Int64?) -> TrafficClassification {
        if let bps = bytesPerSecond {
            switch bps {
                case 0...1249:
                    return .NONE
                case 1250...12499:
                    return .LOW
                case 12500...124999:
                    return .MID
                case 125000...Int64.max - 1: // -1 => bugfix for crash on swift 1.2 (range index has no valid successor or something...)
                    return .HIGH
                default:
                    break
            }
        }

        return .UNKNOWN
    }

}
