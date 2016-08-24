//
//  WifiInfo.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 23.08.16.
//
//

import Foundation
import ObjectMapper

///
class WifiInfo: Mappable {

    ///
    var ssid: String?

    ///
    var bssid: String?

    ///
    var networkId: String?

    ///
    var supplicantState: String?

    ///
    var supplicantStateDetail: String?

    ///
    init() {

    }

    ///
    init(connectivity: RMBTConnectivity) {
        ssid = connectivity.networkName ?? "Unknown"
        bssid = connectivity.bssid
        networkId = "\(connectivity.networkType.rawValue)" // TODO: why is this a string?
    }

    ///
    required init?(_ map: Map) {

    }

    ///
    func mapping(map: Map) {
        ssid        <- map["ssid"]
        bssid       <- map["bssid"]
        networkId   <- map["network_id"]
        supplicantState         <- map["supplicant_state"]
        supplicantStateDetail   <- map["supplicant_state_detail"]
    }
}
