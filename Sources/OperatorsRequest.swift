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
open class OperatorsRequest: BasicRequest {

    public enum ProviderType: String {
        case all = "MFT_ALL"
        case WLAN = "MFT_WLAN"
        case mobile = "MFT_MOBILE"
        case browser = "MFT_BROWSER"
    }
    ///
    var countryCode: String?
    var providerType: ProviderType = .mobile

    init(countryCode: String = "all", type: ProviderType = .mobile) {
        super.init()
        self.countryCode = countryCode
        self.providerType = type
    }
    
    ///
    required public init?(map: Map) {
        super.init(map: map)
    }
    
    ///
    override public func mapping(map: Map) {
        super.mapping(map: map)

        language <- map["language"]
        countryCode <- map["country_code"]
        providerType <- map["provider_type"]
    }
}
