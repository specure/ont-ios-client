//
//  StringMD5Extension.swift
//  RMBT
//
//  Created by Benjamin Pucher on 20.01.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation
import RMBTClientPrivate

///
extension Int {

    func hexString() -> String {
        return String(format: "%02x", self)
    }

}

///
extension NSData {

    func hexString() -> String {
        var string = String()
        for i in UnsafeBufferPointer<UInt8>(start: UnsafeMutablePointer<UInt8>(bytes), count: length) {
            string += Int(i).hexString()
        }
        return string
    }

    func MD5() -> NSData {
        let result = NSMutableData(length: Int(CC_MD5_DIGEST_LENGTH))!
        CC_MD5(bytes, CC_LONG(length), UnsafeMutablePointer<UInt8>(result.mutableBytes))
        return NSData(data: result)
    }

    func SHA1() -> NSData {
        let result = NSMutableData(length: Int(CC_SHA1_DIGEST_LENGTH))!
        CC_SHA1(bytes, CC_LONG(length), UnsafeMutablePointer<UInt8>(result.mutableBytes))
        return NSData(data: result)
    }

}
