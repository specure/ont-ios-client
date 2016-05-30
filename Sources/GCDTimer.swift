//
//  GCDTimer.swift
//  RMBT
//
//  Created by Benjamin Pucher on 09.02.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

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
        if timer != nil {
            let nsecPerSec = Double(NSEC_PER_SEC)
            let dt = dispatch_time(DISPATCH_TIME_NOW, Int64(interval * nsecPerSec))

            dispatch_source_set_timer(timer, dt, DISPATCH_TIME_FOREVER, 0)

            dispatch_source_set_event_handler(timer, block)
            dispatch_resume(timer)
        }

        return timer
    }

}
