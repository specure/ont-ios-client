//
//  RTPPacket.swift
//  RMBT
//
//  Created by Benjamin Pucher on 12.03.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
struct RTPPacket {

    ///
    var header: RTPHeader

    ///
    var payload: NSData // [UInt32]

    //

    ///
    var length: Int {
        return header.length + payload.length
    }

    //

    ///
    init() {
        header = RTPHeader()

        payload = NSData() // [UInt32](count: 1, repeatedValue: 0)
    }

// MARK: to/from data methods

    ///
    func toData() -> NSData {
        let data = NSMutableData()

        data.appendData(header.toData())
        data.appendData(payload)

        return data
    }

    ///
    static func fromData(packetData: NSData) -> RTPPacket? {
        if packetData.length < 12 {
            return nil // packet size too small
        }

        var rtpPacket = RTPPacket()

        var offset = 0

        // header

        if let header = RTPHeader.fromData(packetData) {
            rtpPacket.header = header
            offset = header.length
        } else {
            return nil // header parsing failed
        }

        // payload
        rtpPacket.payload = packetData.subdataWithRange(NSRange(location: offset, length: packetData.length - offset))

        return rtpPacket
    }

}
