//
//  UInt+Extensions.swift
//  RMBT
//
//  Created by Benjamin Pucher on 13.03.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
extension UInt8 {

    ///
    public mutating func setBits(value: UInt8, pos: UInt8) {
        let length = UInt8(floor(log2(Double(value))) + 1)

        self.setBits(value, pos: pos, length: length)
    }

    ///
    public mutating func setBits(value: UInt8, pos: UInt8, length: UInt8) {
        let sizeMinusLength = UInt8(sizeofValue(self) * 8) - length
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
    public mutating func setBits(value: UInt8, pos: UInt16, length: UInt16) {
        self.setBits(UInt16(value), pos: pos, length: length)
    }

    ///
    public mutating func setBits(value: UInt16, pos: UInt16) {
        let length = UInt16(floor(log2(Double(value))) + 1)

        self.setBits(value, pos: pos, length: length)
    }

    ///
    public mutating func setBits(value: UInt16, pos: UInt16, length: UInt16) {
        let sizeMinusLength = UInt16(sizeofValue(self) * 8) - length
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
