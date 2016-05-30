//
//  NSData+Extensions.swift
//  RMBT
//
//  Created by Benjamin Pucher on 12.03.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

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
