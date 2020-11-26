/*****************************************************************************************************
 * Copyright 2016 SPECURE GmbH
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *****************************************************************************************************/

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
    var time: Int?

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

        relativeTimeNs = RMBTTimestampWithNSDate(connectivity.timestamp).intValue
        time = Int(connectivity.timestamp.timeIntervalSince1970)// as Date

        if connectivity.networkType == .cellular {
            networkTypeId = connectivity.cellularCode ?? -1
        } else {
            networkTypeId = connectivity.networkType.rawValue
        }
    }

    ///
    required init?(map: Map) {

    }

    ///
    func mapping(map: Map) {
        relativeTimeNs  <- map["relative_time_ns"]
        networkType     <- map["network_type"]
        networkTypeId   <- map["network_type_id"]
        catTechnology   <- map["cat_technology"]
        if RMBTConfig.sharedInstance.RMBT_VERSION_NEW {
            time            <- (map["time"], IntDateStringTransformOf)
        }
        else {
            time            <- map["time"]
        }
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
