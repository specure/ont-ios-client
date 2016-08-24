//
//  QosMeasurementResultRequest.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 23.08.16.
//
//

import Foundation
import ObjectMapper

///
class QosMeasurementResultRequest: BasicRequest {

    ///
    var measurementUuid: String?

    ///
    var clientUuid: String?

    ///
    var testToken: String?

    ///
    var time: Int?

    ///
    var qosResultList: [QOSTestResults]?

    ///
    override func mapping(map: Map) {
        super.mapping(map)

        measurementUuid <- map["uuid"]
        clientUuid      <- map["client_uuid"]

        testToken       <- map["test_token"]

        time            <- map["time"]

        qosResultList   <- map["qos_result"]
    }
}
