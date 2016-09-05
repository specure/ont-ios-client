//
//  MapMeasurementRequest.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 23.08.16.
//
//

import Foundation
import ObjectMapper

///
class MapMeasurementRequest: BasicRequest {

    ///
    var size = "40" // TODO?

    ///
    var clientUuid: String?

    ///
    var prioritizeUuid: String?

    ///
    var coords: CoordObject?

    ///
    var options: [String: AnyObject]?

    ///
    var filter: [String: AnyObject]?

    ///
    override func mapping(map: Map) {
        super.mapping(map)

        size            <- map["size"]
        clientUuid      <- map["client_uuid"]
        prioritizeUuid  <- map["prioritize"]
        coords          <- map["coords"]
        options         <- map["options"]
        filter          <- map["filter"]
    }

    ///
    internal class CoordObject: Mappable {

        ///
        var latitude: Double?

        ///
        var longitude: Double?

        ///
        var zoom: Int?

        ///
        init() {

        }

        ///
        required internal init?(_ map: Map) {

        }

        ///
        internal func mapping(map: Map) {
            latitude    <- map["lat"]
            longitude   <- map["lon"]
            zoom        <- map["z"]
        }
    }
}
