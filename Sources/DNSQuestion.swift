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
struct DNSQuestion: CustomStringConvertible {
    // var name: String
    var dnsType: UInt16
    var dnsClass: UInt16

    var description: String {
        return "DNSQuestion: [dnsType: \(dnsType), dnsClass: \(dnsClass)]" // name: \(name),
    }

    init() {
        // name = ""
        dnsType = 0
        dnsClass = 0
    }
}
