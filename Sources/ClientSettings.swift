//
//  ClientSettings.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 23.08.16.
//
//

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
    required init?(_ map: Map) {

    }

    ///
    func mapping(map: Map) {
        clientType <- map["clientType"]
        termsAndConditionsAccepted <- map["termsAndConditionsAccepted"]
        termsAndConditionsAcceptedVersion <- map["termsAndConditionsAcceptedVersion"]
        uuid <- map["uuid"]
    }

    ///
    var description: String {
        return "clientType: \(clientType), uuid: \(uuid)"
    }
}
