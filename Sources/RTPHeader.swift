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
struct RTPHeader {

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
        return MemoryLayout<UInt16>.size + MemoryLayout<UInt16>.size + MemoryLayout<UInt32>.size + MemoryLayout<UInt32>.size + (MemoryLayout<UInt32>.size * csrcList.count)
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
    mutating func increaseSequenceNumberBy(_ step: UInt16) {
        sequenceNumber += step
    }

    ///
    mutating func increaseTimestampBy(_ step: UInt32) {
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
    func toData() -> Data {
        var data = Data()
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
    static func fromData(_ packetData: Data) -> RTPHeader? {
        if packetData.count < 12 {
            return nil // packet size too small
        }

        var rtpHeader = RTPHeader()

        var offset = 0

        rtpHeader.flags = packetData.readHostByteOrderUInt16(packetData, atOffset: offset)
        offset += MemoryLayout<UInt16>.size

        rtpHeader.sequenceNumber = packetData.readHostByteOrderUInt16(packetData, atOffset: offset)
        offset += MemoryLayout<UInt16>.size

        rtpHeader.timestamp = packetData.readHostByteOrderUInt32(packetData, atOffset: offset)
        offset += MemoryLayout<UInt32>.size

        rtpHeader.ssrc = packetData.readHostByteOrderUInt32(packetData, atOffset: offset)
        offset += MemoryLayout<UInt32>.size

        // TODO: parse csrcList
        // let csrcCount = rtpPacket.header &

        return rtpHeader
    }

}
