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
extension UInt8 {

    ///
    public mutating func setBits(_ value: UInt8, pos: UInt8) {
        let length = UInt8(floor(log2(Double(value))) + 1)

        self.setBits(value, pos: pos, length: length)
    }

    ///
    public mutating func setBits(_ value: UInt8, pos: UInt8, length: UInt8) {
        let sizeMinusLength = UInt8(MemoryLayout.size(ofValue: self) * 8) - length
        let sizeMinusLengthMinusPos = sizeMinusLength - pos

        var bitmask: UInt8 = UInt8.max
        bitmask <<= pos
        bitmask >>= sizeMinusLength
        bitmask <<= sizeMinusLengthMinusPos
        bitmask = ~bitmask

        let field = (self & bitmask) | (value << sizeMinusLengthMinusPos)

        self = field
    }

}

///
extension UInt16 {

    ///
    public mutating func setBits(_ value: UInt8, pos: UInt16, length: UInt16) {
        self.setBits(UInt16(value), pos: pos, length: length)
    }

    ///
    public mutating func setBits(_ value: UInt16, pos: UInt16) {
        let length = UInt16(floor(log2(Double(value))) + 1)

        self.setBits(value, pos: pos, length: length)
    }

    ///
    public mutating func setBits(_ value: UInt16, pos: UInt16, length: UInt16) {
        let sizeMinusLength = UInt16(MemoryLayout.size(ofValue: self) * 8) - length
        let sizeMinusLengthMinusPos = sizeMinusLength - pos

        var bitmask: UInt16 = UInt16.max
        bitmask <<= pos
        bitmask >>= sizeMinusLength
        bitmask <<= sizeMinusLengthMinusPos
        bitmask = ~bitmask

        let field = (self & bitmask) | (value << sizeMinusLengthMinusPos)

        self = field
    }

}
