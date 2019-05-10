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
open class BasicRequest: Mappable {
    
    /// for compatibility reasons delete when needed
    var uuid:String?
    var loopUuid:String?

    ///
    var apiLevel: String?

    ///
    var clientName: String?

    ///
    var device: String?

    ///
    var language: String?

    ///
    var model: String?

    ///
    var osVersion: String?

    ///
    var platform: String?
    var plattform: String?

    ///
    var product: String?

    ///
    var previousTestStatus: String?

    ///
    var softwareRevision: String?

    ///
    var softwareVersion: String?

    ///
    var clientVersion: String? // TODO: fix this on server side

    ///
    var softwareVersionCode: Int?

    ///
    var softwareVersionName: String?

    ///
    var timezone: String?

    ///
    var clientType: String? // ClientType enum

    ///
    init() {

    }

    ///
    required public init?(map: Map) {

    }

    ///
    public func mapping(map: Map) {
        //
        uuid            <- map["uuid"]
        loopUuid            <- map["loop_uuid"]
        //
        apiLevel            <- map["api_level"]
        clientName          <- map["client_name"]
        device              <- map["device"]

        language            <- map["language"]
        language            <- map["client_language"] // TODO: fix this on server side

        model               <- map["model"]
        osVersion           <- map["os_version"]
        platform            <- map["platform"]
        plattform           <- map["plattform"]
        product             <- map["product"]
        previousTestStatus  <- map["previous_test_status"]
        softwareRevision    <- map["software_revision"]

        softwareVersion     <- map["software_version"]
        softwareVersion     <- map["client_software_version"] // TODO: fix this on server side

        clientVersion       <- map["client_version"] // TODO: fix this on server side

        softwareVersionCode <- map["software_version_code"]
        softwareVersionName <- map["software_version_name"]
        timezone            <- map["timezone"]
        clientType          <- map["client_type"]
    }
}
