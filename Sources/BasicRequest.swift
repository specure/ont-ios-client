//
//  BasicRequest.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 23.08.16.
//
//

import Foundation
import ObjectMapper

///
class BasicRequest: Mappable {

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
    required init?(_ map: Map) {

    }

    ///
    func mapping(map: Map) {
        apiLevel            <- map["api_level"]
        clientName          <- map["client_name"]
        device              <- map["device"]

        language            <- map["language"]
        language            <- map["client_language"] // TODO: fix this on server side

        model               <- map["model"]
        osVersion           <- map["os_version"]
        platform            <- map["platform"]
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
