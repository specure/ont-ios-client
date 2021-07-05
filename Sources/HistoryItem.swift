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

///{
///    "device": "string",
///    "measurement_date": "string",
///    "network_type": "string",
///    "ping": 0,
///    "qos": 0,
///    "speed_download": 0,
///    "speed_upload": 0,
///    "test_uuid": "string",
///    "voip_result_jitter_millis": 0,
///    "voip_result_packet_loss_percents": 0
///  }
///
open class HistoryItem: BasicResponse {
    open var testUuid: String?
    open var measurementDate: Date?
    open var device: String?
    open var model: String?
    
    open var speedDownload: Int?
    open var speedUpload: Int?
    open var ping: Int?
    open var qos: Int?
    open var jitter: Int?
    open var packetLoss: Int?
    
    open var networkType: String?
    open var networkName: String?

    ///
    override open func mapping(map: Map) {
        super.mapping(map: map)
        testUuid           <- map["test_uuid"]
        measurementDate    <- (map["measurement_date"], DateStringTimezoneTransformOf)
        device             <- map["device"]
        model             <- map["model"]
        ping               <- map["ping"]
        qos                <- map["qos"]
        speedUpload        <- map["speed_upload"]
        speedDownload      <- map["speed_download"]
        jitter             <- map["voip_result_jitter_millis"]
        packetLoss         <- map["voip_result_packet_loss_percents"]
        networkType        <- map["network_type"]
        networkName        <- map["network_name"]
    }
}
