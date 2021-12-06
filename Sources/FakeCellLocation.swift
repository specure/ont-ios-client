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
class FakeCellLocation: Mappable {

    ///
    var areaCode: Int? = 3

    ///
    var primaryScramblingCode: Int? = -1

    ///
    var time: Int? = 0

    ///
    var location_id: Int? = 91

    ///
    init() {
        time = Int(Date().timeIntervalSince1970)
    }

    ///
    required init?(map: Map) {

    }

    ///
    func mapping(map: Map) {
        areaCode                     <- map["area_code"]
        primaryScramblingCode        <- map["primary_scrambling_code"]
        time                         <- map["time"]
        location_id                  <- map["location_id"]
    }
}
