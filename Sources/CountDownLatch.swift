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
    private var count: UInt8 = 0

    ///
    private let mutualExclusionQueue = dispatch_queue_create("com.specure.rmbt.cdl.mutualExclusionQueue", DISPATCH_QUEUE_SERIAL)

    ///
    private let semaphore = dispatch_semaphore_create(0)

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
        dispatch_sync(mutualExclusionQueue) { // dispatch_sync
            if self.count == 0 {
                return
            }

            self.count -= 1
            if self.count == 0 {
                logger.debug("signal semaphore")
                dispatch_semaphore_signal(self.semaphore)
            }
        }
    }

    ///
    func await(timeout: UInt64) -> Bool {
        let dt = dispatch_time(DISPATCH_TIME_NOW, Int64(timeout))
        let ret = dispatch_semaphore_wait(self.semaphore, dt)

        return (ret == 0)
    }

}
