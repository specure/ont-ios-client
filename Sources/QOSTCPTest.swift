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
class QOSTCPTest: QOSTest {

    private let PARAM_PORT_OUT = "out_port"
    private let PARAM_PORT_IN = "in_port"

    //

    var portOut: UInt16?
    var portIn: UInt16?

    //

    ///
    override var description: String {
        return super.description + ", [portOut: \(String(describing: portOut)), portIn: \(String(describing: portIn))]"
    }

    //

    ///
    override init(testParameters: QOSTestParameters) {
        // portOut
        if let portOutString = testParameters[PARAM_PORT_OUT] as? String {
            if let portOut = UInt16(portOutString) {
                self.portOut = portOut
            }
        }

        // portIn
        if let portInString = testParameters[PARAM_PORT_IN] as? String {
            if let portIn = UInt16(portInString) {
                self.portIn = portIn
            }
        }

        super.init(testParameters: testParameters)
    }

    ///
    override func getType() -> QosMeasurementType! {
        return .TCP
    }

}
