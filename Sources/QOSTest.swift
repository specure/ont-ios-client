//
//  QOSTest.swift
//  RMBT
//
//  Created by Benjamin Pucher on 05.12.14.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

import Foundation

///
class QOSTest: CustomStringConvertible { /* TODO: declarations in extensions cannot be overriden yet */ // should be abstract

    let PARAM_TEST_UID = "qos_test_uid"
    let PARAM_CONCURRENCY_GROUP = "concurrency_group"
    let PARAM_SERVER_ADDRESS = "server_addr"
    let PARAM_SERVER_PORT = "server_port"
    let PARAM_TIMEOUT = "timeout"

    // values from server

    /// The id of this QOS test (provided by control server)
    var qosTestId: UInt = 0 // TODO: make this field optional?

    /// The concurrency group of this QOS test (provided by control server)
    var concurrencyGroup: UInt = 0 // TODO: make this field optional?

    /// The server address of this QOS test (provided by control server)
    var serverAddress: String = "_server_address"// TODO: make this field optional?

    /// The server port of this QOS test (provided by control server)
    var serverPort: UInt16 = 443 // TODO: make this field optional?

    /// The general timeout in nano seconds of this QOS test (provided by control server)
    var timeout: UInt64 = QOS_DEFAULT_TIMEOUT_NS

    //

    var testStartTimestampNS: UInt64?
    var testEndTimestampNS: UInt64?

    var hasStarted: Bool = false
    var hasFinished: Bool = false

    //

    ///
    var description: String {
        return "QOSTest(\(getType()?.rawValue)) [id: \(qosTestId), concurrencyGroup: \(concurrencyGroup), serverAddress: \(serverAddress), serverPort: \(serverPort), timeout: \(timeout)]"
    }

    //

    ///
    init(testParameters: QOSTestParameters) {

        // qosTestId
        if let qosTestIdString = testParameters[PARAM_TEST_UID] as? String {
            if let qosTestId = UInt(qosTestIdString) {
                self.qosTestId = qosTestId
            }
        }

        // concurrencyGroup
        if let concurrencyGroupString = testParameters[PARAM_CONCURRENCY_GROUP] as? String {
            if let concurrencyGroup = UInt(concurrencyGroupString) {
                self.concurrencyGroup = concurrencyGroup
            }
        }

        // serverAddress
        if let serverAddress = testParameters[PARAM_SERVER_ADDRESS] as? String {
            // TODO: length check on url?
            self.serverAddress = serverAddress
        }

        // serverPort
        if let serverPortString = testParameters[PARAM_SERVER_PORT] as? String {
            if let serverPort = UInt16(serverPortString) {
                self.serverPort = serverPort
            }
        }

        // timeout
        if let timeoutString = testParameters[PARAM_TIMEOUT] as? NSString {
            let timeout = timeoutString.longLongValue
            if timeout > 0 {
                self.timeout = UInt64(timeout)
            }
        }
    }

    //

    /// returns the type of this test object
    func getType() -> QOSMeasurementType! {
        return nil
    }

}

// MARK: Printable methods

///
// extension QOSTest: Printable {
//
//    ///
//    var description: String {
//        return "QOSTest(\(getType().rawValue)) [id: \(qosTestId), concurrencyGroup: \(concurrencyGroup), serverAddress: \(serverAddress), serverPort: \(serverPort), timeout: \(timeout)]"
//    }
// }
