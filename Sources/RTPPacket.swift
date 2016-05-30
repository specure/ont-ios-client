//
//  RTPPacket.swift
//  RMBT
//
//  Created by Benjamin Pucher on 12.03.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
public struct RTPHeader {

    ///
    var flags: UInt16

    ///
    var sequenceNumber: UInt16

    ///
    var timestamp: UInt32

    ///
    var ssrc: UInt32

    ///
    var csrcList: [UInt32]

    //

    ///
    var version: UInt8 {
        get {
            return UInt8((flags >> 14) & 0x3)
        }
        set(newVersion) {
            flags.setBits(newVersion, pos: 0, length: 2)
        }
    }

    ///
    var padding: UInt8 {
        get {
            // return UInt8((flags >> 14) & 0x3)
            return UInt8((flags >> 13) & 0x1)
        }
        set(newPadding) {
            flags.setBits(newPadding, pos: 2, length: 1)
        }
    }

    ///
    var ext: UInt8 {
        get {
            return UInt8((flags >> 12) & 0x1)
        }
        set(newExt) {
            flags.setBits(newExt, pos: 3, length: 1)
        }
    }

    ///
    var csrcCount: UInt8 {
        get {
            return UInt8((flags >> 8) & 0xF)
        }
        set(newCsrcCount) {
            flags.setBits(newCsrcCount, pos: 4, length: 4)
        }
    }

    ///
    var marker: UInt8 {
        get {
            return UInt8((flags >> 7) & 0x1)
        }
        set(newMarker) {
            flags.setBits(newMarker, pos: 8, length: 1)
        }
    }

    ///
    var payloadType: UInt8 {
        get {
            return UInt8(flags & 0x7F)
        }
        set(newPayloadType) {
            flags.setBits(newPayloadType, pos: 9, length: 7)
        }
    }

    //

    ///
    var length: Int {
        return sizeof(UInt16) + sizeof(UInt16) + sizeof(UInt32) + sizeof(UInt32) + (sizeof(UInt32) * csrcList.count)
    }

    //

    ///
    init() {
        flags = 0

        //

        sequenceNumber = 0
        timestamp = 0
        ssrc = 0

        csrcList = [UInt32]() // [UInt32](count: 15, repeatedValue: 0) // ?

        //

        version = 2
        padding = 0
        ext = 0
        csrcCount = 0
    }

    ///
    public mutating func increaseSequenceNumberBy(step: UInt16) {
        sequenceNumber += step
    }

    ///
    public mutating func increaseTimestampBy(step: UInt32) {
        timestamp += step
    }

// MARK: to/from data methods

    ///
//    public func toData() -> NSData {
//        var data = NSMutableData()
//
//        data.appendValue(flags)
//        data.appendValue(sequenceNumber)
//        data.appendValue(timestamp)
//        data.appendValue(ssrc)
//
//        for csrc in csrcList {
//            data.appendValue(csrc)
//        }
//
//        return data
//    }

    ///
    public func toData() -> NSData {
        let data = NSMutableData()

        data.appendValue(flags.bigEndian)
        data.appendValue(sequenceNumber.bigEndian)
        data.appendValue(timestamp.bigEndian)
        data.appendValue(ssrc.bigEndian)

        // for csrc in csrcList {
        for cnt in 0 ..< Int(self.csrcCount) {
            data.appendValue(csrcList[cnt].bigEndian)
        }

        return data
    }

    ///
    public static func fromData(packetData: NSData) -> RTPHeader? {
        if packetData.length < 12 {
            return nil // packet size too small
        }

        var rtpHeader = RTPHeader()

        var offset = 0

        rtpHeader.flags = packetData.readHostByteOrderUInt16(packetData, atOffset: offset)
        offset += sizeof(UInt16)

        rtpHeader.sequenceNumber = packetData.readHostByteOrderUInt16(packetData, atOffset: offset)
        offset += sizeof(UInt16)

        rtpHeader.timestamp = packetData.readHostByteOrderUInt32(packetData, atOffset: offset)
        offset += sizeof(UInt32)

        rtpHeader.ssrc = packetData.readHostByteOrderUInt32(packetData, atOffset: offset)
        offset += sizeof(UInt32)

        // TODO: parse csrcList
        // let csrcCount = rtpPacket.header &

        return rtpHeader
    }

}

///
public struct RTPPacket {

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
    public func toData() -> NSData {
        let data = NSMutableData()

        data.appendData(header.toData())
        data.appendData(payload)

        return data
    }

    ///
    public static func fromData(packetData: NSData) -> RTPPacket? {
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
