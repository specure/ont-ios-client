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
struct DNSResourceRecord: CustomStringConvertible {
    var namePointer: UInt8
    var dnsType: UInt16
    var dnsClass: UInt16
    var ttl: UInt32
    // var ttl1: UInt16
    // var ttl2: UInt16
    var dataLength: UInt16

    var description: String {
        return "DNSResourceRecord: [namePointer: \(namePointer), dnsType: \(dnsType), dnsClass: \(dnsClass), ttl: \(ttl), dataLength: \(dataLength)]"
        // return "DNSResourceRecord: [namePointer: \(namePointer), dnsType: \(dnsType), dnsClass: \(dnsClass), ttl: \(ttl1), \(ttl2), dataLength: \(dataLength)]"
    }

    // 8 bit => name pointer?
    // 16 bit => service type
    // 16 bit => service class
    // 32 bit => ttl
    // 16 bit => data length
    // data-length * 8 bit => data

    init() {
        namePointer = 0
        dnsType = 0
        dnsClass = 0
        ttl = 0
        // ttl1 = 0
        // ttl2 = 0
        dataLength = 0
    }
}
