//
//  DNSHeader.swift
//  DNSTest
//
//  Created by Benjamin Pucher on 10.03.15.
//  Copyright © 2015 Benjamin Pucher. All rights reserved.
//

import Foundation

///
struct DNSHeader: CustomStringConvertible {
    var id: UInt16
    var flags: UInt16
    var qdCount: UInt16
    var anCount: UInt16
    var nsCount: UInt16
    var arCount: UInt16

    var description: String {
        return "DNSHeader: [id: \(id), flags: \(flags), qdCount: \(qdCount), anCount: \(anCount), nsCount: \(nsCount), arCount: \(arCount)]"
    }

    init() {
        id = 0
        flags = 0
        qdCount = 0
        anCount = 0
        nsCount = 0
        arCount = 0
    }
}
