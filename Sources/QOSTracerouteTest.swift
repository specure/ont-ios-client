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
class QOSTracerouteTest: QOSTest {

    fileprivate let PARAM_HOST = "host"
    fileprivate let PARAM_MAX_HOPS = "max_hops"

    //

    var host: String?
    var maxHops: UInt8 = 64

    /// config values not configured on server
    var noResponseTimeout: TimeInterval = 1 // x seconds
    var bytesPerPackage: UInt16 = 72 // 72 bytes
    var triesPerTTL: UInt8 = 1 // x tries per ttl
    ///

    //

    ///
    override var description: String {
        return super.description + ", [host: \(String(describing: host)), maxHops: \(maxHops), noResponseTimeout: \(noResponseTimeout), bytesPerPackage: \(bytesPerPackage), triesPerTTL: \(triesPerTTL)]"
    }

    //

    ///
    override init(testParameters: QOSTestParameters) {
        if let host = testParameters[PARAM_HOST] as? String {
            // TODO: length check on host?
            self.host = host
        }

        // max hops
        if let maxHopsString = testParameters[PARAM_MAX_HOPS] as? String {
            if let maxHops = UInt8(maxHopsString) {
                self.maxHops = maxHops
            }
        }

        super.init(testParameters: testParameters)
    }

    ///
    override func getType() -> QosMeasurementType! {
        return .TRACEROUTE
    }
}
