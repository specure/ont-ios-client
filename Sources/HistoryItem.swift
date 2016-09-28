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
public class HistoryItem: BasicResponse {

    ///
    public var testUuid: String?

    ///
    public var time: UInt64?

    ///
    public var timeZone: String?

    ///
    public var timeString: String?

    ///
    public var qosResultAvailable = false

    ///
    public var speedDownload: String?

    ///
    public var speedUpload: String?

    ///
    public var ping: String?

    ///
    public var pingShortest: String?

    ///
    public var model: String?

    ///
    public var networkType: String?

    ///
    public var speedDownloadClassification: Int?

    ///
    public var speedUploadClassification: Int?

    ///
    public var pingClassification: Int?

    ///
    public var pingShortClassification: Int?

    ///
    override public func mapping(map: Map) {
        super.mapping(map)

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
    }
}
