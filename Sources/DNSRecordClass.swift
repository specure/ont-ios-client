//
//  DNSRecordClass.swift
//  DNSTest
//
//  Created by Benjamin Pucher on 10.03.15.
//  Copyright © 2015 Benjamin Pucher. All rights reserved.
//

import Foundation

let DNS_RCODE_TABLE: [UInt8: String] = [
    0: "NOERROR",
    1: "FORMERR",
    2: "SERVFAIL",
    3: "NXDOMAIN",
    4: "NOTIMP",
    //4: "NOTIMPL",
    5: "REFUSED",
    6: "YXDOMAIN",
    7: "YXRRSET",
    8: "NXRRSET",
    9: "NOTAUTH",
    10: "NOTZONE",
    16: "BADVERS",
    //16: "BADSIG",
    17: "BADKEY",
    18: "BADTIME",
    19: "BADMODE"
]

///
class DNSRecordClass: CustomStringConvertible {
    let name: String
    var qType: UInt16!
    var qClass: UInt16!
    var ttl: UInt32!

    let rcode: UInt8

    // TODO: improve...use struct...

    ///
    var ipAddress: String?

    ///
    var mxPreference: UInt16?
    var mxExchange: String?

    //

    ///
    var description: String {
        if let addr = ipAddress {
            return addr
        }

        return "\(ipAddress)"
    }

    //

    ///
    init(name: String, qType: UInt16, qClass: UInt16, ttl: UInt32, rcode: UInt8) {
        self.name = name
        self.qType = qType
        self.qClass = qClass
        self.ttl = ttl
        self.rcode = rcode
    }

    ///
    init(name: String, rcode: UInt8) {
        self.name = name
        self.rcode = rcode
    }

    ///
    func rcodeString() -> String {
        return DNS_RCODE_TABLE[rcode] ?? "UNKNOWN" // !
    }

}
