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
class CountDownLatch {

    ///
    fileprivate var count: UInt8 = 0

    ///
    fileprivate let mutualExclusionQueue = DispatchQueue(label: "com.specure.rmbt.cdl.mutualExclusionQueue", attributes: [])

    ///
    fileprivate let semaphore = DispatchSemaphore(value: 0)

    ///
    convenience init() {
        self.init(1)
    }

    ///
    init(_ count: UInt8) {
        if count > 0 {
            self.count = count
        }
    }

    ///
    func countDown() {
        mutualExclusionQueue.sync { // dispatch_sync
            if self.count == 0 {
                return
            }

            self.count -= 1
            if self.count == 0 {
                Log.logger.debug("signal semaphore")
                self.semaphore.signal()
            }
        }
    }

    ///
    func await(_ timeout: UInt64) -> Bool {
        let dt = DispatchTime.now() + Double(Int64(timeout)) / Double(NSEC_PER_SEC)
        let ret = self.semaphore.wait(timeout: dt)

        return (ret == .success)
    }

}
