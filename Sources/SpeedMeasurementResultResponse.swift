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
open class SpeedMeasurementResultResponse: BasicResponse {

    ///
    open var classifiedMeasurementDataList: [ClassifiedResultItem]?

    ///
    open var networkDetailList: [ResultItem]?

    ///
    open var networkType: Int?

    ///
    open var openTestUuid: String?

    ///
    open var openUuid: String?

    ///
    open var time: Int?

    ///
    open var timeString: String?

    ///
    open var timezone: String?

    ///
    open var location: String?

    ///
    open var latitude: Double?

    ///
    open var longitude: Double?

    ///
    open var shareText: String?

    ///
    open var shareSubject: String?

    //////////// only for map

    ///
    open var highlight = false

    ///
    open var measurementUuid: String?

    ////////////

    ///
    override open func mapping(map: Map) {
        super.mapping(map: map)

        classifiedMeasurementDataList <- map["measurement"]
        networkDetailList <- map["net"]

        networkType <- map["network_type"]

        openTestUuid <- map["open_test_uuid"]
        openUuid <- map["open_uuid"]
        time <- map["time"]
        timeString <- map["time_string"]
        timezone <- map["timezone"]
        location <- map["location"]
        latitude <- map["geo_lat"]
        longitude <- map["geo_long"]
        shareText <- map["share_text"]
        shareSubject <- map["share_subject"]

        // only for map
        highlight <- map["highlight"]
        measurementUuid <- map["measurement_uuid"]
    }

    ///
    override open var description: String {
        return "SpeedMeasurementResultResponse [\(String(describing: openTestUuid)),\(String(describing: latitude)),\(String(describing: longitude))]"
    }

    ///
    open class ResultItem: Mappable {

        ///
        open var value: String?

        ///
        open var title: String?

        ///
        init() {

        }

        ///
        required public init?(map: Map) {

        }

        ///
        open func mapping(map: Map) {
            value <- map["value"]
            title <- map["title"]
        }
    }

    ///
    open class ClassifiedResultItem: ResultItem {

        ///
        open var classification: Int?

        ///
        override open func mapping(map: Map) {
            super.mapping(map: map)

            classification <- map["classification"]
        }
    }
}
