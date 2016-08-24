//
//  TelephonyInfo.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 23.08.16.
//
//

import Foundation
import ObjectMapper

///
class TelephonyInfo: Mappable {

    ///
    var dataState: Int?

    ///
    var networkCountry: String?

    ///
    var networkIsRoaming: Bool?

    ///
    var networkOperator: String?

    ///
    var networkOperatorName: String?

    ///
    var networkSimCountry: String?

    ///
    var networkSimOperator: String?

    ///
    var networkSimOperatorName: String?

    ///
    var phoneType: Int?

    ///
    init() {

    }

    ///
    init(connectivity: RMBTConnectivity) {
        networkOperatorName = connectivity.networkName ?? "Unknown"
        networkSimOperator  = connectivity.telephonyNetworkSimOperator
        networkSimCountry   = connectivity.telephonyNetworkSimCountry
    }

    ///
    required init?(_ map: Map) {

    }

    ///
    func mapping(map: Map) {
        dataState           <- map["data_state"]
        networkCountry      <- map["network_country"]
        networkIsRoaming    <- map["network_is_roaming"]

        networkOperator     <- map["network_operator"]
        networkOperatorName <- map["network_operator_name"]

        networkSimCountry       <- map["network_sim_country"]
        networkSimOperator      <- map["network_sim_operator"]
        networkSimOperatorName  <- map["network_sim_operator_name"]
        phoneType               <- map["phone_type"]
    }
}
