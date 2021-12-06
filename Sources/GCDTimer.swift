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
    fileprivate var timerSource: DispatchSourceTimer!

    ///
    fileprivate let timerQueue: DispatchQueue

    ///
    init() {
        // ??????
        // timerQueue = DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default)
        timerQueue = DispatchQueue(label: "com.specure.nettest.timer", attributes: .concurrent)
    }

    ///
    deinit {
        defer {
            stop()
        }
    }

    ///
    func start() {
        if let interval = self.interval {
            stop() // stop any previous timer

            // start new timer
            timerSource = createTimer(interval, timerQueue: timerQueue) {
                Log.logger.debug("timer fired")
                self.stop()

                self.timerCallback?()
            }
        }
    }

    ///
    func stop() {
        if timerSource != nil {
            timerSource.cancel()
        }
    }

    ///
    private func createTimer(_ interval: Double, timerQueue: DispatchQueue, block: @escaping ()->()) -> DispatchSourceTimer {
        let timer = DispatchSource.makeTimerSource(/*flags: DispatchSource.TimerFlags(rawValue: 0),*/ queue: timerQueue)

        let nsecPerSec = Double(NSEC_PER_SEC)
        let dt = DispatchTime.now() + Double(Int64(interval * nsecPerSec)) / Double(NSEC_PER_SEC)
        
        //let distantFuture = DispatchTime.distantFuture.uptimeNanoseconds
//        //
        let zeroInterval = DispatchTimeInterval.seconds(0)

        timer.schedule(deadline: dt, leeway: zeroInterval)        

        timer.setEventHandler { // `[weak self]` only needed if you reference `self` in this closure and you want to prevent strong reference cycle
            block()
        }
        
        timer.resume()
        
// Original solution 
        
//        let timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, timerQueue)
//        
//        let nsecPerSec = Double(NSEC_PER_SEC)
//        let dt = dispatch_time(DISPATCH_TIME_NOW, Int64(interval * nsecPerSec))
//        
//        dispatch_source_set_timer(timer, dt, DISPATCH_TIME_FOREVER, 0)
//        
//        dispatch_source_set_event_handler(timer, block)
//        dispatch_resume(timer)

        return timer 
    }

}
