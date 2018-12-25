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
open class HistoryItem: BasicResponse {
    
    /// ONT
    open var jpl:VoipTest?

    ///
    open var testUuid: String?

    ///
    open var time: UInt64?

    ///
    open var timeZone: String?

    ///
    open var timeString: String?

    ///
    open var qosResultAvailable = false

    ///
    open var speedDownload: String?

    ///
    open var speedUpload: String?

    ///
    open var ping: String?

    ///
    open var pingShortest: String?

    ///
    open var model: String?

    ///
    open var networkType: String?

    ///
    open var speedDownloadClassification: Int?

    ///
    open var speedUploadClassification: Int?

    ///
    open var pingClassification: Int?

    ///
    open var pingShortClassification: Int?
    
    open var networkName: String?
    open var operatorName: String?
    
    open var qosResult: String?

    ///
    override open func mapping(map: Map) {
        super.mapping(map: map)
        //
        jpl           <- map["jpl"]
        //

        testUuid           <- map["test_uuid"]
        time               <- (map["time"], UInt64NSNumberTransformOf)
        timeZone           <- map["time_zone"]
        timeString         <- map["time_string"]
        qosResultAvailable <- map["qos_result_available"]
        speedDownload      <- map["speed_download"]
        speedUpload        <- map["speed_upload"]
        ping               <- map["ping"]
        pingShortest       <- map["ping_shortest"]
        model              <- map["model"]
        networkType        <- map["network_type"]
        speedDownloadClassification <- map["speed_download_classification"]
        speedUploadClassification   <- map["speed_upload_classification"]
        pingClassification          <- map["ping_classification"]
        pingShortClassification     <- map["ping_short_classification"]
        networkName         <- map["network_name"]
        operatorName         <- map["operator"]
        qosResult           <- map["qos_result"]
    }
}
