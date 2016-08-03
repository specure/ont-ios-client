//
//  QOSMeasurementType.swift
//  RMBT
//
//  Created by Benjamin Pucher on 05.12.14.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

import Foundation

///
public enum QOSMeasurementType: String { // TODO: rename to QosMeasurementType
    case HttpProxy              = "http_proxy"
    case NonTransparentProxy    = "non_transparent_proxy"
    case WEBSITE                = "website"
    case DNS                    = "dns"
    case TCP                    = "tcp"
    case UDP                    = "udp"
    case VOIP                   = "voip"
    case TRACEROUTE             = "traceroute"

    ///
    static var localizedNameDict = [QOSMeasurementType: String]()
}

///
extension QOSMeasurementType: CustomStringConvertible {

    ///
    public var description: String {
        return QOSMeasurementType.localizedNameDict[self] ?? self.rawValue
    }
}
