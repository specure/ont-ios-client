/*****************************************************************************************************
 * Copyright 2014-2016 SPECURE GmbH
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *****************************************************************************************************/

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
        return super.description + ", [request: \(String(describing: request)), port: \(String(describing: port))]"
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
    override func getType() -> QosMeasurementType! {
        return .NonTransparentProxy
    }

}
