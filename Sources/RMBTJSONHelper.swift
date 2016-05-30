//
//  RMBTJSONHelper.swift
//  RMBT
//
//  Created by Benjamin Pucher on 20.01.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
func jsonValueOrNull(obj: AnyObject!) -> AnyObject {
    return obj != nil ? obj : NSNull()
}

/* func jsonValueOrNull<T : AnyObject>(obj: T?) -> T {
    return obj != nil ? obj! : NSNull()
} */

///
func jsonize(value: UInt64) -> NSNumber {
    return NSNumber(unsignedLongLong: value)
}
