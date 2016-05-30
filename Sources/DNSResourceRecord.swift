//
//  DNSResourceRecord.swift
//  DNSTest
//
//  Created by Benjamin Pucher on 10.03.15.
//  Copyright © 2015 Benjamin Pucher. All rights reserved.
//

import Foundation

///
struct DNSResourceRecord: CustomStringConvertible {
    var namePointer: UInt16
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

    // 16 bit => name pointer?
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
