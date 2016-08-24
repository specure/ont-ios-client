//
//  GeoLocation.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 23.08.16.
//
//

import Foundation
import ObjectMapper
import CoreLocation

///
class GeoLocation: Mappable {

    ///
    var latitude: Double?

    ///
    var longitude: Double?

    ///
    var accuracy: Double?

    ///
    var altitude: Double?

    ///
    var bearing: Double?

    ///
    var speed: Double?

    ///
    var provider: String?

    ///
    var relativeTimeNs: Int?

    ///
    var time: NSDate?

    ///
    init() {

    }

    ///
    init(location: CLLocation) {
        latitude        = location.coordinate.latitude
        longitude       = location.coordinate.longitude
        accuracy        = location.horizontalAccuracy
        altitude        = location.altitude

        #if os(iOS)
        bearing         = location.course
        speed           = (location.speed > 0.0 ? location.speed : 0.0)
        provider        = "GPS" // TODO?
        #else
        provider        = "WiFi" // TODO?
        #endif

        relativeTimeNs  = 0 // TODO?
        time            = location.timestamp // TODO?
    }

    ///
    required init?(_ map: Map) {

    }

    ///
    func mapping(map: Map) {
        latitude        <- map["latitude"]
        longitude       <- map["longitude"]
        accuracy        <- map["accuracy"]
        altitude        <- map["altitude"]
        bearing         <- map["bearing"]
        speed           <- map["speed"]
        provider        <- map["provider"]
        time            <- map["time"]
        relativeTimeNs  <- map["relative_time_ns"]
    }

}
