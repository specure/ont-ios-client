//
//  QOSTestType.swift
//  RMBT
//
//  Created by Benjamin Pucher on 05.12.14.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

import Foundation

///
enum QOSTestType: String {
    case HttpProxy              = "http_proxy"
    case NonTransparentProxy    = "non_transparent_proxy"
    case WEBSITE                = "website"
    case DNS                    = "dns"
    case TCP                    = "tcp"
    case UDP                    = "udp"
    case VOIP                   = "voip"
    case TRACEROUTE             = "traceroute"

    ///
    static var localizedNameDict = [QOSTestType: String]()
}

///
extension QOSTestType: CustomStringConvertible {

    ///
    var description: String {
        return QOSTestType.localizedNameDict[self] ?? self.rawValue
    }
}
