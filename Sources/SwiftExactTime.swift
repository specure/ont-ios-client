//
//  SwiftExactTime.swift
//  RMBT
//
//  Created by Benjamin Pucher on 20.01.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
public func currentTimeMillis() -> UInt64 {
    return UInt64(NSDate().timeIntervalSince1970 * 1000)
}

///
public func nanoTime() -> UInt64 {
    return ticksToNanoTime(getCurrentTimeTicks())
}

///
public func getCurrentTimeTicks() -> UInt64 {
    return mach_absolute_time()
}

///
public func ticksToNanoTime(ticks: UInt64) -> UInt64 {
    var sTimebaseInfo = mach_timebase_info(numer: 0, denom: 0)
    mach_timebase_info(&sTimebaseInfo)

    let nano: UInt64 = (ticks * UInt64(sTimebaseInfo.numer) / UInt64(sTimebaseInfo.denom))

    return nano
}

///
public func getTimeDifferenceInNanoSeconds(fromTicks: UInt64) -> UInt64 {
    let to: UInt64 = mach_absolute_time()
    let elapsed: UInt64 = to - fromTicks

    return ticksToNanoTime(elapsed)
}
