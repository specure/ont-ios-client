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
class GCDTimer {

    typealias TimerCallback = () -> ()

    ///
    var timerCallback: TimerCallback?

    ///
    var interval: Double?

    ///
    private var timerSource: dispatch_source_t!

    ///
    private let timerQueue: dispatch_queue_t

    ///
    init() {
        timerQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    }

    ///
    deinit {
        stop()
    }

    ///
    func start() {
        if let interval = self.interval {
            stop() // stop any previous timer

            // start new timer
            timerSource = createTimer(interval, timerQueue: timerQueue) {
                logger.debug("timer fired")
                self.stop()

                self.timerCallback?()
            }
        }
    }

    ///
    func stop() {
        if timerSource != nil {
            dispatch_source_cancel(timerSource)
        }
    }

    ///
    private func createTimer(interval: Double, timerQueue: dispatch_queue_t, block: dispatch_block_t) -> dispatch_source_t {
        let timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, timerQueue)

        let nsecPerSec = Double(NSEC_PER_SEC)
        let dt = dispatch_time(DISPATCH_TIME_NOW, Int64(interval * nsecPerSec))

        dispatch_source_set_timer(timer, dt, DISPATCH_TIME_FOREVER, 0)

        dispatch_source_set_event_handler(timer, block)
        dispatch_resume(timer)

        return timer
    }

}
