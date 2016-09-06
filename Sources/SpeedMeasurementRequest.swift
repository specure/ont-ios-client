//
//  SpeedMeasurementRequest.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 23.08.16.
//
//

import Foundation
import ObjectMapper

///
class SpeedMeasurementRequest: BasicRequest {

    ///
    var uuid: String?

    ///
    var ndt = false

    ///
    var anonymous = false

    ///
    var time: UInt64?

    ///
    var version: String?

    ///
    var testCounter: UInt?

    ///
    var geoLocation: GeoLocation?

    ///
    override func mapping(map: Map) {
        super.mapping(map)

        uuid        <- map["uuid"]
        ndt         <- map["ndt"]
        anonymous   <- map["anonymous"]
        time        <- (map["time"], UInt64NSNumberTransformOf)
        version     <- map["version"]
        testCounter <- map["test_counter"]

        geoLocation <- map["geo_location"]
    }
}
