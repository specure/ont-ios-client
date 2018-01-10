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
open class MapOptionResponse: BasicResponse {

    ///
    var mapTypeList: [MapOptionType]?

    ///
    var mapFilterList: [String: [MapOptionType]]?
    
    var countries: [MapOptionCountry]?

    ///
    override open func mapping(map: Map) {
        super.mapping(map: map)

        mapTypeList <- map["mapfilter.mapTypes"]
        mapFilterList <- map["mapfilter.mapFilters"]
        countries <- map["mapCountries"]
    }

    open class MapOptionCountry: Mappable {
        var code: String?
        var name: String?
        
        ///
        init() {
            
        }
        
        ///
        required public init?(map: Map) {
            
        }
        
        ///
        open func mapping(map: Map) {
            code <- map["country_code"]
            name <- map["country_name"]
        }
    }
    
    ///
    open class MapOptionType: Mappable {

        ///
        var title: String?

        ///
        var options: [/*MapOption*/[String: AnyObject]]?

        ///
        init() {

        }

        ///
        required public init?(map: Map) {

        }

        ///
        open func mapping(map: Map) {
            title   <- map["title"]
            options <- map["options"]
        }

        ///
        open class MapOption: Mappable {

            ///
            var title: String?

            ///
            var summary: String?

            ///
            var isDefault = false

            ///
            var statisticalMethod: String?

            ///
            var period: String?

            ///
            var provider: String?

            ///
            var technology: String?

            ///
            init() {

            }

            ///
            required public init?(map: Map) {

            }

            ///
            open func mapping(map: Map) {
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
