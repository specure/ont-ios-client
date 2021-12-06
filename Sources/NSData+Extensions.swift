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
protocol WriteToNSMutableData {

}

extension Data: WriteToNSMutableData {
    ///
    public mutating func appendValue<T>(_ data: T) {
        var incomeData = data
        
        withUnsafePointer(to: &incomeData) { p in
            self.append(Data(bytes: p, count: MemoryLayout.size(ofValue: data)))
        }
    }
    
    ///
    public mutating func appendValue<T>(_ data: T, size: Int) {
        var data = data
        
        withUnsafePointer(to: &data) { p in
            self.append(Data(bytes: p, count: size))
        }
    }
}

///
extension NSMutableData: WriteToNSMutableData {

    ///
    public func appendValue<T>(_ data: T) {
        var incomeData = data

        withUnsafePointer(to: &incomeData) { p in
            self.append(p, length: MemoryLayout.size(ofValue: data))
        }
    }

    ///
    public func appendValue<T>(_ data: T, size: Int) {
        var data = data

        withUnsafePointer(to: &data) { p in
            self.append(p, length: size)
        }
    }

}

///
protocol ReadFromNSData {

}

///
extension Data: ReadFromNSData {

    ///
    public func readUInt16(_ data: Data, atOffset offset: Int) -> UInt16 {
        var value: UInt16 = 0

        (data as NSData).getBytes(&value, range: NSRange(location: offset, length: MemoryLayout<UInt16>.size))

        return value
    }

    ///
    public func readHostByteOrderUInt16(_ data: Data, atOffset offset: Int) -> UInt16 {
        return CFSwapInt16BigToHost(readUInt16(data, atOffset: offset))
    }

    ///
    public func readUInt32(_ data: Data, atOffset offset: Int) -> UInt32 {
        var value: UInt32 = 0

        (data as NSData).getBytes(&value, range: NSRange(location: offset, length: MemoryLayout<UInt32>.size))

        return value
    }

    ///
    public func readHostByteOrderUInt32(_ data: Data, atOffset offset: Int) -> UInt32 {
        return CFSwapInt32BigToHost(readUInt32(data, atOffset: offset))
    }

}

extension Data {
    func extractFirstDNSResourceName(separator: UInt8) -> (string: String?, offset: Int) {
        if self.count > 0,
            self[0] == separator {
            return (nil, 0)
        }
        
        let values = self.split(separator: separator)
        
        if let value = values.first {
            return Data(value).extractStringByOctets()
        } else {
            return (nil, 0)
        }
    }
    
    func extractStringByOctets() -> (string: String?, offset: Int) {
        var offset = 0
        var strings: [String] = []
        while offset < self.count {
            let value: Int = Int(self[offset])
            offset += 1
            guard value != 0 else { break }
            
            if let string = String(data: self.subdata(in: offset..<(offset + value)), encoding: .utf8) {
                strings.append(string)
            }
            offset += value
        }
        
        return (strings.joined(separator: "."), offset)
    }
}

