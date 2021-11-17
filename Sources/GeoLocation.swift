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
import CoreLocation

final class GeoLocation: Mappable {
    var latitude: Double?
    var longitude: Double?
    var accuracy: Double?
    var altitude: Double?
    var heading: Double?
    var speed: Double?
    var provider: String?
    var relativeTimeNs: Int?
    var time: Date?
    var postalCode: String?
    var city: String?
    var country: String?
    var county: String?

    init() { }

    init(location: CLLocation) {
        latitude        = location.coordinate.latitude
        longitude       = location.coordinate.longitude
        accuracy        = location.horizontalAccuracy
        altitude        = location.altitude

        #if os(iOS)
        heading         = location.course
        speed           = (location.speed > 0.0 ? location.speed : 0.0)
        provider        = "GPS"
        #else
        provider        = "WiFi"
        #endif
        
        time = location.timestamp
    }
    
    required init?(map: Map) { }

    func mapping(map: Map) {
        //Duplicate coordinates because some api requered lat and long and another geo_lat and geo_long
        latitude        <- map["geo_lat"]
        longitude       <- map["geo_long"]
        latitude        <- map["lat"]
        longitude       <- map["long"]
        accuracy        <- map["accuracy"]
        altitude        <- map["altitude"]
        speed           <- map["speed"]
        time            <- (map["tstamp"], DateStringTimezoneTransformOf)
        provider        <- map["provider"]
        heading         <- map["heading"] // ???
        heading         <- map["bearing"] // ???
        city            <- map["city"]
        country         <- map["country"]
        county          <- map["county"]
        postalCode      <- map["postalCode"]
    }
    
    /*
    {
      "geo_lat": 0,
      "geo_long": 0,
      "accuracy": 0,
      "altitude": 0,
      "bearing": 0,
      "speed": 0,
      "tstamp": "2021-09-22T11:28:23.984Z",
      "provider": "string"
    }
     */
}
