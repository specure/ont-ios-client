//
//  QOSDNSTest.swift
//  RMBT
//
//  Created by Benjamin Pucher on 05.12.14.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

import Foundation

///
class QOSDNSTest: QOSTest {

    private let PARAM_HOST = "host"
    private let PARAM_RESOLVER = "resolver"
    private let PARAM_RECORD = "record"

    //

    ///
    var host: String?

    ///
    var resolver: String?

    ///
    var record: String?

    //

    ///
    override var description: String {
        return super.description + ", [host: \(host), resolver: \(resolver), record: \(record)]"
    }

    //

    ///
    override init(testParameters: QOSTestParameters) {
        // host
        if let host = testParameters[PARAM_HOST] as? String {
            // TODO: length check on host?
            self.host = host
        }

        // resolver
        if let resolver = testParameters[PARAM_RESOLVER] as? String {
            // TODO: length check on resolver?
            self.resolver = resolver
        }

        // record
        if let record = testParameters[PARAM_RECORD] as? String {
            // TODO: length check on record?
            self.record = record
        }

        super.init(testParameters: testParameters)
    }

    ///
    override func getType() -> QOSMeasurementType! {
        return .DNS
    }

}
