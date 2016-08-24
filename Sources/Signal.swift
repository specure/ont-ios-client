//
//  Signal.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 23.08.16.
//
//

import Foundation
import ObjectMapper

///
class Signal: Mappable {

    ///
    var relativeTimeNs: Int?

    ///
    var networkType: String? // result only

    ///
    var networkTypeId = -1

    ///
    var catTechnology: String? // results only

    ///
    var time: NSDate?

    ///
    var signalStrength: Int?

    ///
    var wifiLinkSpeed: Int? // http://stackoverflow.com/questions/16878982/ios-get-link-speed-router-speed-test

    ///
    var wifiRssi: Int? // not available on iOS

    ///
    var gsmBitErrorRate: Int? // not available on iOS

    ///
    var lteRsrp: Int? // not available on iOS

    ///
    var lteRsrq: Int? // not available on iOS

    ///
    var lteRssnr: Int? // not available on iOS

    ///
    var lteCqi: Int? // not available on iOS

    ///
    init() {

    }

    ///
    init(connectivity: RMBTConnectivity) {
        // TODO: additional fields?

        relativeTimeNs = RMBTTimestampWithNSDate(connectivity.timestamp).integerValue
        time = connectivity.timestamp

        if connectivity.networkType == .Cellular {
            networkTypeId = connectivity.cellularCode.integerValue
        } else {
            networkTypeId = connectivity.networkType.rawValue
        }
    }

    ///
    required init?(_ map: Map) {

    }

    ///
    func mapping(map: Map) {
        relativeTimeNs  <- map["relative_time_ns"]
        networkType     <- map["network_type"]
        networkTypeId   <- map["network_type_id"]
        catTechnology   <- map["cat_technology"]
        time            <- map["time"]
        signalStrength  <- map["signal_strength"]
        wifiLinkSpeed   <- map["wifi_link_speed"]
        wifiRssi        <- map["wifi_rssi"]
        gsmBitErrorRate <- map["gsm_bit_error_rate"]
        lteRsrp         <- map["lte_rsrp"]
        lteRsrq         <- map["lte_rsrq"]
        lteRssnr        <- map["lte_rssnr"]
        lteCqi          <- map["lte_cqi"]
    }
}
