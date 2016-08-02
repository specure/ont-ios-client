//
//  QOSWebsiteTest.swift
//  RMBT
//
//  Created by Benjamin Pucher on 05.12.14.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

import Foundation

///
class QOSWebsiteTest: QOSTest {

    private let PARAM_URL = "url"

    //

    /// The url of the website test (provided by control server)
    var url: String?

    //

    ///
    override var description: String {
        return super.description + ", [url: \(url)]"
    }

    //

    ///
    override init(testParameters: QOSTestParameters) {
        // url
        if let url = testParameters[PARAM_URL] as? String {
            // TODO: length check on url?
            self.url = url
        }

        super.init(testParameters: testParameters)
    }

    ///
    override func getType() -> QOSMeasurementType! {
        return .WEBSITE
    }
}
