//
//  QosMeasurmentResponse.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 23.08.16.
//
//

import Foundation
import ObjectMapper

///
class QosMeasurmentResponse: BasicResponse {

    ///
    var testToken: String?

    ///
    var testUuid: String?

    ///
    var objectives: [String: [[String: AnyObject]]]?

    ///
    override func mapping(map: Map) {
        super.mapping(map)

        testToken <- map["test_token"]
        testUuid <- map["test_uuid"]

        objectives <- map["objectives"]
    }

    ///
    override var description: String {
        return "QosMeasurmentResponse: testToken: \(testToken), testUuid: \(testUuid), objectives: \n\(objectives)"
    }
}
