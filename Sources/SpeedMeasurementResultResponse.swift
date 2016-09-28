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
public class SpeedMeasurementResultResponse: BasicResponse {

    ///
    public var classifiedMeasurementDataList: [ClassifiedResultItem]?

    ///
    public var networkDetailList: [ResultItem]?

    ///
    public var networkType: Int?

    ///
    public var openTestUuid: String?

    ///
    public var openUuid: String?

    ///
    public var time: Int?

    ///
    public var timeString: String?

    ///
    public var timezone: String?

    ///
    public var location: String?

    ///
    public var latitude: Double?

    ///
    public var longitude: Double?

    ///
    public var shareText: String?

    ///
    public var shareSubject: String?

    //////////// only for map

    ///
    public var highlight = false

    ///
    public var measurementUuid: String?

    ////////////

    ///
    override public func mapping(map: Map) {
        super.mapping(map)

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
    override public var description: String {
        return "SpeedMeasurementResultResponse [\(openTestUuid),\(latitude),\(longitude)]"
    }

    ///
    public class ResultItem: Mappable {

        ///
        public var value: String?

        ///
        public var title: String?

        ///
        init() {

        }

        ///
        required public init?(_ map: Map) {

        }

        ///
        public func mapping(map: Map) {
            value <- map["value"]
            title <- map["title"]
        }
    }

    ///
    public class ClassifiedResultItem: ResultItem {

        ///
        public var classification: Int?

        ///
        override public func mapping(map: Map) {
            super.mapping(map)

            classification <- map["classification"]
        }
    }
}
