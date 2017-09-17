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
struct RTPResult {

    ///
    var jitterMap: [UInt16: Double]

    ///
    var receivedPackets: UInt16

    ///
    var maxJitter: Int64

    ///
    var meanJitter: Int64

    ///
    var skew: Int64

    ///
    var maxDelta: Int64

    ///
    var outOfOrder: UInt16

    ///
    var minSequential: UInt16

    ///
    var maxSequential: UInt16

    //

    ///
    init() {
        jitterMap = [UInt16: Double]()
        receivedPackets = 0
        maxJitter = 0
        meanJitter = 0
        skew = 0
        maxDelta = 0
        outOfOrder = 0
        minSequential = 0
        maxSequential = 0
    }

    ///
    init(jitterMap: [UInt16: Double], maxJitter: Int64, meanJitter: Int64, skew: Int64, maxDelta: Int64, outOfOrder: UInt16, minSequential: UInt16, maxSequential: UInt16) {
        self.jitterMap = jitterMap
        self.receivedPackets = UInt16(jitterMap.count)
        self.maxJitter = maxJitter
        self.meanJitter = meanJitter
        self.skew = skew
        self.maxDelta = maxDelta
        self.outOfOrder = outOfOrder
        self.minSequential = (minSequential > receivedPackets) ? receivedPackets : minSequential
        self.maxSequential = (maxSequential > receivedPackets) ? receivedPackets : maxSequential
    }
}

///
extension RTPResult: CustomStringConvertible {

    ///
    var description: String {
        return "RTPResult: [jitterMap: \(jitterMap), maxJitter: \(maxJitter), meanJitter: \(meanJitter), " +
               "skew: \(skew), maxDelta: \(maxDelta), outOfOrder: \(outOfOrder), minSequential: \(minSequential), maxSequential: \(maxSequential)]"
    }
}
