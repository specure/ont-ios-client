//
//  SettingsRequest.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 23.08.16.
//
//

import Foundation
import ObjectMapper

///
class SettingsRequest: BasicRequest {

    ///
    var client: ClientSettings?

    ///
    override func mapping(map: Map) {
        super.mapping(map)

        client <- map["client"]
    }

}
