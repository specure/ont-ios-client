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
