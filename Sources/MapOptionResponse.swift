//
//  MapOptionResponse.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 23.08.16.
//
//

import Foundation
import ObjectMapper

///
public class MapOptionResponse: BasicResponse {

    ///
    var mapTypeList: [MapOptionType]?

    ///
    var mapFilterList: [String: [MapOptionType]]?

    ///
    override public func mapping(map: Map) {
        super.mapping(map)

        mapTypeList <- map["mapfilter.mapTypes"]
        mapFilterList <- map["mapfilter.mapFilters"]
    }

    ///
    public class MapOptionType: Mappable {

        ///
        var title: String?

        ///
        var options: [/*MapOption*/[String: AnyObject]]?

        ///
        init() {

        }

        ///
        required public init?(_ map: Map) {

        }

        ///
        public func mapping(map: Map) {
            title   <- map["title"]
            options <- map["options"]
        }

        ///
        public class MapOption: Mappable {

            ///
            var title: String?

            ///
            var summary: String?

            ///
            var isDefault = false

            ///
            var statisticalMethod: String?

            ///
            var period: Int?

            ///
            var provider: String?

            ///
            var technology: String?

            ///
            init() {

            }

            ///
            required public init?(_ map: Map) {

            }

            ///
            public func mapping(map: Map) {
                title       <- map["title"]
                summary     <- map["summary"]
                isDefault   <- map["default"]
                statisticalMethod <- map["statistical_method"]
                period      <- map["period"]
                provider    <- map["provider"]
                technology  <- map["technology"]
            }
        }
    }
}
