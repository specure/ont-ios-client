//
//  QOSNonTransparentProxyTest.swift
//  RMBT
//
//  Created by Benjamin Pucher on 05.12.14.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

import Foundation

///
class QOSNonTransparentProxyTest: QOSTest {

    private let PARAM_REQUEST = "request"
    private let PARAM_PORT = "port"

    //

    /// The request string to use by the non-transparent proxy test (provided by control server)
    var request: String?

    /// The port to test by the non-transparent proxy test (provided by control server)
    var port: UInt16?

    //

    ///
    override var description: String {
        return super.description + ", [request: \(request), port: \(port)]"
    }

    //

    ///
    override init(testParameters: QOSTestParameters) {
        // request
        if let request = testParameters[PARAM_REQUEST] as? String {
            // TODO: length check on request?
            self.request = request

            // append newline character if not already added
            if !self.request!.hasSuffix("\n") {
                self.request! += "\n"
            }
        }

        // port
        if let portString = testParameters[PARAM_PORT] as? String {
            if let port = UInt16(portString) {
                self.port = port
            }
        }

        super.init(testParameters: testParameters)
    }

    ///
    override func getType() -> QOSMeasurementType! {
        return .NonTransparentProxy
    }

}
