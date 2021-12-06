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

public extension UInt64 {
    ///
    static func currentTimeMillis() -> UInt64 {
        return UInt64(Date().timeIntervalSince1970 * 1000)
    }

    ///
    static func nanoTime() -> UInt64 {
        return ticksToNanoTime(getCurrentTimeTicks())
    }

    ///
    static func getCurrentTimeTicks() -> UInt64 {
        return mach_absolute_time()
    }

    ///
    static func ticksToNanoTime(_ ticks: UInt64) -> UInt64 {
        var sTimebaseInfo = mach_timebase_info(numer: 0, denom: 0)
        mach_timebase_info(&sTimebaseInfo)

        let nano: UInt64 = (ticks * UInt64(sTimebaseInfo.numer) / UInt64(sTimebaseInfo.denom))

        return nano
    }

    ///
    static func getTimeDifferenceInNanoSeconds(_ fromTicks: UInt64) -> UInt64 {
        let to: UInt64 = mach_absolute_time()
        let elapsed: UInt64 = to - fromTicks

        return ticksToNanoTime(elapsed)
    }
    
    func toNanoTime() -> UInt64 {
        return self * NSEC_PER_SEC
    }
    
    func toMilisecondsTime() -> UInt64 {
        return self * USEC_PER_SEC
    }
}
