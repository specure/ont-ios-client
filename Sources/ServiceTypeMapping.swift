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
#if swift(>=3.2)
    import Darwin
    import dnssd
#else
    import RMBTClientPrivate
#endif

// TODO: is this the Rcode?
/* enum DNSStatus {
OK = 0
BAD_HANDLE = 1
MALFORMED_QUERY = 2
TIMEOUT = 3
SEND_FAILED = 4
RECEIVE_FAILED = 5
CONNECTION_FAILED = 6
WRONG_SERVER = 7
WRONG_XID = 8
WRONG_QUESTION = 9
} */

let DNSServiceTypeStrToInt: [String: Int] = [
    "A":        kDNSServiceType_A,
    //    "NS":       kDNSServiceType_NS,
    "CNAME":    kDNSServiceType_CNAME,
    //    "SOA":      kDNSServiceType_SOA,
    //    "PTR":      kDNSServiceType_PTR,
    "MX":       kDNSServiceType_MX,
    //    "TXT":      kDNSServiceType_TXT,
    "AAAA":     kDNSServiceType_AAAA,
    //    "SRV":      kDNSServiceType_SRV,
    //"A6":       kDNSServiceType_A6,
    //    "SPF":      kDNSServiceType_SPF
]

let DNSServiceTypeIntToStr: [Int: String] = [
    kDNSServiceType_A:      "A",
    //    kDNSServiceType_NS:     "NS",
    kDNSServiceType_CNAME:  "CNAME",
    //    kDNSServiceType_SOA:    "SOA",
    //    kDNSServiceType_PTR:    "PTR",
    kDNSServiceType_MX:     "MX",
    //    kDNSServiceType_TXT:    "TXT",
    kDNSServiceType_AAAA:   "AAAA",
    //    kDNSServiceType_SRV:    "SRV",
    //kDNSServiceType_A6:     "A6",
    //    kDNSServiceType_SPF:    "SPF"
]
