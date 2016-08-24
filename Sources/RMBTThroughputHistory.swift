//
//  RMBTThroughputHistory.swift
//  RMBT
//
//  Created by Benjamin Pucher on 31.03.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
public class RMBTThroughputHistory: CustomStringConvertible {

    /// Total bytes/time transferred so far. Equal to sum of all reported lengths / largest reported timestamp.
    public var totalThroughput = RMBTThroughput(length: 0, startNanos: 0, endNanos: 0)

    /// Time axis is split into periods of this duration. Each period has a throughput object associated with it.
    /// Reported transfers are then proportionally divided accross the throughputs it spans over.
    public var resolutionNanos: UInt64

    /// Array of throughput objects for each period
    public var periods = [RMBTThroughput]()

    /// Returns the index of the last period which is complete, meaning that no reports can change its value.
    /// -1 if not even the first period is complete yet
    public var lastFrozenPeriodIndex: Int = -1

    /// See freeze
    public var isFrozen: Bool = false

    //

    ///
    public init(resolutionNanos: UInt64) {
        self.resolutionNanos = resolutionNanos
    }

    ///
    func addLength(length: UInt64, atNanos timestampNanos: UInt64) {
        assert(!isFrozen, "Tried adding to frozen history")

        totalThroughput.length += length
        totalThroughput.endNanos = max(totalThroughput.endNanos, timestampNanos)

        if periods.count == 0 {
            // Create first period
            periods.append(RMBTThroughput(length: 0, startNanos: 0, endNanos: 0))
        }

        var leftoverLength = length

        let startPeriodIndex = periods.count - 1
        var endPeriodIndex = timestampNanos / resolutionNanos

        if timestampNanos - (resolutionNanos * endPeriodIndex) == 0 {
            endPeriodIndex -= 1 // Boundary condition
        }

        assert(startPeriodIndex > lastFrozenPeriodIndex, "Start period \(startPeriodIndex) < \(lastFrozenPeriodIndex)")
        assert(Int(endPeriodIndex) > lastFrozenPeriodIndex, "End period \(endPeriodIndex) < \(lastFrozenPeriodIndex)")

        //

        let startPeriod = periods[startPeriodIndex]

        let transferNanos = timestampNanos - startPeriod.endNanos
        assert(transferNanos > 0, "Transfer happened before last reported transfer?")

        let lengthPerPeriod = UInt64(Double(length) * (Double(resolutionNanos) / Double(transferNanos))) // TODO: improve

        if startPeriodIndex == Int(endPeriodIndex) {
            // Just add to the start period
            startPeriod.length += length
            startPeriod.endNanos = timestampNanos
        } else {
            // Attribute part to the start period, except if we started on the boundary
            if startPeriod.endNanos < (UInt64(startPeriodIndex) + 1) * resolutionNanos {

                // TODO: improve calculation
                let startLength = UInt64(Double(length) * (Double(resolutionNanos - (startPeriod.endNanos % resolutionNanos)) / Double(transferNanos)))

                startPeriod.length += startLength
                startPeriod.endNanos = (UInt64(startPeriodIndex) + 1) * resolutionNanos
                leftoverLength -= startLength
            }

            // Create periods in between
            for i: UInt64 in (UInt64(startPeriodIndex) + 1) ..< endPeriodIndex {
                leftoverLength -= lengthPerPeriod

                periods.append(RMBTThroughput(length: lengthPerPeriod, startNanos: i * resolutionNanos, endNanos: (i + 1) * resolutionNanos))
            }

            // Create new end period and add the rest of bytes to it
            periods.append(RMBTThroughput(length: leftoverLength, startNanos: endPeriodIndex * resolutionNanos, endNanos: timestampNanos))
        }

        lastFrozenPeriodIndex = Int(endPeriodIndex) - 1
    }

    /// Marks history as frozen, also marking all periods as passed, not allowing futher reports.
    func freeze() {
        isFrozen = true
        lastFrozenPeriodIndex = periods.count - 1
    }

    /// Concatenetes last count periods into one, or nop if there are less than two periods in the history.
    func squashLastPeriods(count: Int) {
        assert(count >= 1, "Count must be >= 1")
        assert(isFrozen, "History should be frozen before squashing")

        if periods.count < count {
            return
        }

        let finalTput = periods[periods.count - count - 1]

        for _ in 0 ..< count {
            let t = periods.last!

            finalTput.endNanos = max(t.endNanos, finalTput.endNanos)
            finalTput.length += t.length

            periods.removeLast()
        }
    }

    ///
    func log() {
        logger.debug("Throughputs:")

        for t in periods {
            logger.debug("- \(t.description)")
        }

        logger.debug("Total: \(self.totalThroughput.description)")
    }

    ///
    public var description: String {
        return "total = \(totalThroughput), entries = \(periods.description)"
    }
}
