//
//  HopDetail.swift
//  RMBT
//
//  Created by Benjamin Pucher on 17.02.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
public class HopDetail: NSObject { /* struct */
    //    var transmitted: UInt64
    //    var received: UInt64
    //    var errors: UInt64
    //    var packetLoss: UInt64

    ///
    private var timeTries = [UInt64]()

    ///
    public var time: UInt64 { // return middle value
        var t: UInt64 = 0

        for ti: UInt64 in timeTries {
            t += ti
        }

        return t / UInt64(timeTries.count)
        // return UInt64.divideWithOverflow(t, UInt64(timeTries.count)).0
    }

    ///
    public var fromIp: String!

    ///
    public func addTry(time: UInt64) {
        timeTries.append(time)
    }

    ///
    public func getAsDictionary() -> [String: AnyObject] {
        return [
            "host": jsonValueOrNull(fromIp),
            "time": NSNumber(unsignedLongLong: time)
        ]
    }

    ///
    public override var description: String {
        return "HopDetail: fromIp: \(fromIp), time: \(time)"
    }
}
