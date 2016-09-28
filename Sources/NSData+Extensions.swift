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

///
extension NSMutableData: WriteToNSMutableData {

    ///
    public func appendValue<T>(data: T) {
        var data = data

        withUnsafePointer(&data) { p in
            self.appendBytes(p, length: sizeofValue(data))
        }
    }

    ///
    public func appendValue<T>(data: T, size: Int) {
        var data = data

        withUnsafePointer(&data) { p in
            self.appendBytes(p, length: size)
        }
    }

}

///
protocol ReadFromNSData {

}

///
extension NSData: ReadFromNSData {

    ///
    public func readUInt16(data: NSData, atOffset offset: Int) -> UInt16 {
        var value: UInt16 = 0

        data.getBytes(&value, range: NSRange(location: offset, length: sizeof(UInt16)))

        return value
    }

    ///
    public func readHostByteOrderUInt16(data: NSData, atOffset offset: Int) -> UInt16 {
        return CFSwapInt16BigToHost(readUInt16(data, atOffset: offset))
    }

    ///
    public func readUInt32(data: NSData, atOffset offset: Int) -> UInt32 {
        var value: UInt32 = 0

        data.getBytes(&value, range: NSRange(location: offset, length: sizeof(UInt32)))

        return value
    }

    ///
    public func readHostByteOrderUInt32(data: NSData, atOffset offset: Int) -> UInt32 {
        return CFSwapInt32BigToHost(readUInt32(data, atOffset: offset))
    }

}
