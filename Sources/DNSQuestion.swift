//
//  DNSQuestion.swift
//  DNSTest
//
//  Created by Benjamin Pucher on 10.03.15.
//  Copyright © 2015 Benjamin Pucher. All rights reserved.
//

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
