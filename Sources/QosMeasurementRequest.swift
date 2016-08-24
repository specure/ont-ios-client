//
//  QosMeasurementRequest.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 23.08.16.
//
//

import Foundation
import ObjectMapper

///
class QosMeasurementRequest: BasicRequest {

    ///
    var clientUuid: String?

    ///
    var measurementUuid: String?

    ///
    override func mapping(map: Map) {
        super.mapping(map)

        clientUuid <- map["clientUuid"]
        measurementUuid <- map["measurementUuid"]
    }
}
