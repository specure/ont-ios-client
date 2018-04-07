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
struct RTPPacket {

    ///
    var header: RTPHeader

    ///
    var payload: Data // [UInt32]

    //

    ///
    var length: Int {
        return header.length + payload.count
    }

    //

    ///
    init() {
        header = RTPHeader()

        payload = Data() // [UInt32](count: 1, repeatedValue: 0)
    }

// MARK: to/from data methods

    ///
    func toData() -> Data {
        var data = Data()
        
        data.append(header.toData())
        data.append(payload)
        
        return data
    }

    ///
    static func fromData(_ packetData: Data) -> RTPPacket? {
        if packetData.count < 12 {
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
        // rtpPacket.payload = packetData.subdata(in: NSRange(location: offset, length: packetData.count - offset))
        // let r = offset..<packetData.count-offset

        rtpPacket.payload = Data(packetData.subdata(in: offset..<packetData.count))

        return rtpPacket
    }

}
