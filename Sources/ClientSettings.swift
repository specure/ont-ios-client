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
class ClientSettings: Mappable, CustomStringConvertible {

    ///
    var clientType = ""

    ///
    var termsAndConditionsAccepted = false

    ///
    var termsAndConditionsAcceptedVersion = 0

    ///
    var uuid: String?

    ///
    init() {

    }

    ///
    required init?(map: Map) {

    }

    ///
    func mapping(map: Map) {
        clientType <- map["clientType"]
        termsAndConditionsAccepted <- map["termsAndConditionsAccepted"] // ["terms_and_conditions_accepted": true]
        termsAndConditionsAcceptedVersion <- map["termsAndConditionsAcceptedVersion"]
        uuid <- map["uuid"]
    }

    ///
    var description: String {
        return "clientType: \(clientType), uuid: \(String(describing: uuid))"
    }
}
