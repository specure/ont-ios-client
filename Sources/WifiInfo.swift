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
    required init?(map: Map) {

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
