//
//  ServiceTypeMapping.swift
//  DNSTest
//
//  Created by Benjamin Pucher on 10.03.15.
//  Copyright © 2015 Benjamin Pucher. All rights reserved.
//

import Foundation
import ifaddrs

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

let DNSServiceTypeStrToInt: [String:Int] = [
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

let DNSServiceTypeIntToStr: [Int:String] = [
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
