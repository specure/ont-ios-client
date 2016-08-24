//
//  SpeedMeasurementDetailResultResponse.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 23.08.16.
//
//

import Foundation
import ObjectMapper

///
public class SpeedMeasurementDetailResultResponse: BasicResponse {

    ///
    public var speedMeasurementResultDetailList: [SpeedMeasurementDetailItem]?

    ///
    override public func mapping(map: Map) {
        super.mapping(map)

        speedMeasurementResultDetailList <- map["testresultdetail"]
    }

    ///
    public class SpeedMeasurementDetailItem: Mappable {

        ///
        public var key: String?

        ///
        public var value: String?

        ///
        public var title: String?

        ///
        public init() {

        }

        ///
        required public init?(_ map: Map) {

        }

        ///
        public func mapping(map: Map) {
            key <- map["key"]
            value <- map["value"]
            title <- map["title"]
        }
    }
}
