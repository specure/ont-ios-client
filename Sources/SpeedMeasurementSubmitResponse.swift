//
//  SpeedMeasurementSubmitResponse.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 23.08.16.
//
//

import Foundation
import ObjectMapper

///
class SpeedMeasurementSubmitResponse: BasicResponse {

    ///
    var openTestUuid: String?

    ///
    var testUuid: String?

    ///
    override func mapping(map: Map) {
        super.mapping(map)

        openTestUuid <- map["open_test_uuid"]
        testUuid <- map["test_uuid"]
    }
}
