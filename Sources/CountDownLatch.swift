//
//  CountDownLatch.swift
//  RMBT
//
//  Created by Benjamin Pucher on 12.02.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

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
