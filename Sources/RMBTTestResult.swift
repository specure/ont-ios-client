//
//  RMBTTestResult.swift
//  RMBT
//
//  Created by Benjamin Pucher on 03.04.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation
import CoreLocation

let RMBTTestResultSpeedNotAvailable = -1
let RMBTTestResultSpeedMeasurementFinished = -2

///
class RMBTTestResult {

    ///
    var threadCount: Int!

    ///
    let resolutionNanos: UInt64

    ///
    var pings = [Ping]()

    ///
    var bestPingNanos: UInt64 = 0

    ///
    var medianPingNanos: UInt64 = 0

    ///
    let totalDownloadHistory: RMBTThroughputHistory

    ///
    let totalUploadHistory: RMBTThroughputHistory

    ///
    weak var totalCurrentHistory: RMBTThroughputHistory!

    ///
    var currentHistories: NSMutableArray!//[RMBTThroughputHistory]!

    ///
    var perThreadDownloadHistories: NSMutableArray!//[RMBTThroughputHistory]()

    ///
    var perThreadUploadHistories: NSMutableArray!//[RMBTThroughputHistory]()

    /// "extended_test_stat": {
    ///     "cpu_usage": {
    ///         "values": [
    ///             {
    ///                 "time_ns": 528015139,
    ///                 "value": 93.1053695678711
    ///             },
    ///             ...
    ///         ]
    ///     },
    ///     "mem_usage": {
	///         "values": [
    ///             {
    ///                 "time_ns": 528015139,
    ///                 "value": 93.1053695678711
    ///             },
    ///             ...
    ///         ]
    ///     }
    /// }
    ///
    var extendedTestStat = [String:[String:[[String:AnyObject]]]]()

    ///
    var locations = [CLLocation]()

    ///
    var testStartNanos: UInt64 = 0

    ///
    var testStartDate: NSDate!

    ///
    private var maxFrozenPeriodIndex: Int!

    ///
    private var connectivities = [RMBTConnectivity]()

    //

    ///
    init(resolutionNanos nanos: UInt64) {
        self.resolutionNanos = nanos

        self.totalDownloadHistory = RMBTThroughputHistory(resolutionNanos: nanos)
        self.totalUploadHistory = RMBTThroughputHistory(resolutionNanos: nanos)

        extendedTestStat["cpu_usage"] = Dictionary()//[String:[[String:AnyObject]]]()
        extendedTestStat["cpu_usage"]!["values"] = Array()//[[String:AnyObject]]()

        extendedTestStat["mem_usage"] = Dictionary()//[String:[[String:AnyObject]]]()
        extendedTestStat["mem_usage"]!["values"] = Array()//[[String:AnyObject]]()
    }

    ///
    func markTestStart() {
        testStartNanos = RMBTCurrentNanos()
        testStartDate = NSDate()
    }

    ///
    func addPingWithServerNanos(serverNanos: UInt64, clientNanos: UInt64) {
        assert(testStartNanos > 0)

        let ping: Ping = Ping(serverNanos: serverNanos, clientNanos: clientNanos, relativeTimestampNanos: RMBTCurrentNanos() - testStartNanos)
        pings.append(ping)

        if bestPingNanos == 0 || bestPingNanos > serverNanos {
            bestPingNanos = serverNanos
        }

        if bestPingNanos > clientNanos {
            bestPingNanos = clientNanos
        }

        // Take median from server pings as "best" ping
        let sortedPings = pings.sort { (p1: Ping, p2: Ping) -> Bool in
            return p1.serverNanos < p2.serverNanos // TODO: is this correct?
        }

        let sortedPingsCount = sortedPings.count

        if sortedPingsCount % 2 == 1 {
            // Uneven number of pings, median is right in the middle
            let i = (sortedPingsCount - 1) / 2
            medianPingNanos = sortedPings[i].serverNanos
        } else {
            // Even number of pings, median is defined as average of two middle elements
            let i = sortedPingsCount / 2
            medianPingNanos = (sortedPings[i].serverNanos + sortedPings[i - 1].serverNanos) / 2 // TODO: is division correct? should divisor be casted to double?
        }
    }

    ///
    func addLength(length: UInt64, atNanos ns: UInt64, forThreadIndex threadIndex: Int) -> [RMBTThroughput]! {
        assert(threadIndex >= 0 && threadIndex < threadCount, "Invalid thread index")

        let h = currentHistories.objectAtIndex(threadIndex) as! RMBTThroughputHistory//currentHistories[threadIndex]
        h.addLength(length, atNanos: ns)

        // TODO: optimize calling updateTotalHistory only when certain preconditions are met

        return updateTotalHistory()
    }

    ///
    func addCpuUsage(cpuUsage: Float, atNanos ns: UInt64) {
        let cpuUsageDict: [String:NSNumber] = [
            "time_ns":  NSNumber(unsignedLongLong: ns),
            "value":    NSNumber(float: cpuUsage)
        ]

        extendedTestStat["cpu_usage"]!["values"]!.append(cpuUsageDict)
    }

    ///
    func addMemoryUsage(ramUsage: Float, atNanos ns: UInt64) {
        let ramUsageDict: [String:NSNumber] = [
            "time_ns":  NSNumber(unsignedLongLong: ns),
            "value":    NSNumber(float: ramUsage)
        ]

        extendedTestStat["mem_usage"]!["values"]!.append(ramUsageDict)
    }

    /// Returns array of throughputs in intervals for which all threads have reported speed
    private func updateTotalHistory() -> [RMBTThroughput]! {
        var commonFrozenPeriodIndex = Int.max

        for h in currentHistories {
            commonFrozenPeriodIndex = min(commonFrozenPeriodIndex, (h as! RMBTThroughputHistory).lastFrozenPeriodIndex)
        }

        // TODO: assert ==
        if commonFrozenPeriodIndex == Int.max || commonFrozenPeriodIndex <= maxFrozenPeriodIndex {
            return nil
        }

        for i in maxFrozenPeriodIndex + 1...commonFrozenPeriodIndex {
        //for var i = maxFrozenPeriodIndex + 1; i <= commonFrozenPeriodIndex; i += 1 {
            if i == commonFrozenPeriodIndex && (currentHistories.objectAtIndex(0) as! RMBTThroughputHistory).isFrozen { //currentHistories[0].isFrozen) {
                // We're adding up the last throughput, clip totals according to spec
                // 1) find t*
                var minEndNanos: UInt64 = 0
                var minPeriodIndex: UInt64 = 0

                for threadIndex in 0 ..< threadCount {
                    let threadHistory = currentHistories.objectAtIndex(threadIndex) as! RMBTThroughputHistory //currentHistories[threadIndex]
                    assert(threadHistory.isFrozen)

                    let threadLastFrozenPeriodIndex = threadHistory.lastFrozenPeriodIndex

                    let threadLastTput = threadHistory.periods[threadLastFrozenPeriodIndex]
                    if minEndNanos == 0 || threadLastTput.endNanos < minEndNanos {
                        minEndNanos = threadLastTput.endNanos
                        minPeriodIndex = UInt64(threadLastFrozenPeriodIndex)
                    }
                }

                // 2) Add up bytes in proportion to t*
                var length: UInt64 = 0

                for threadIndex in 0 ..< threadCount {
                    let threadLastPut = (currentHistories[threadIndex] as! RMBTThroughputHistory).periods[Int(minPeriodIndex)]
                    // Factor = (t*-t(k,m-1)/t(k,m)-t(k,m-1))
                    let factor = Double(minEndNanos - threadLastPut.startNanos) / Double(threadLastPut.durationNanos)

                    assert(factor >= 0.0 && factor <= 1.0, "Invalid factor")

                    length += UInt64(factor) * threadLastPut.length
                }

                totalCurrentHistory.addLength(length, atNanos: minEndNanos)
            } else {
                var length: UInt64 = 0

                for threadIndex in 0 ..< threadCount {
                    let tt = (currentHistories[threadIndex] as! RMBTThroughputHistory).periods[i]
                    length += tt.length

                    assert(totalCurrentHistory.totalThroughput.endNanos == tt.startNanos, "Period start time mismatch")
                }

                totalCurrentHistory.addLength(length, atNanos: UInt64(i + 1) * resolutionNanos)
            }
        }

        let result = (totalCurrentHistory.periods as NSArray).subarrayWithRange(
            NSRange(location: maxFrozenPeriodIndex + 1, length: commonFrozenPeriodIndex - maxFrozenPeriodIndex)
        ) as! [RMBTThroughput]
        //var result = Array(totalCurrentHistory.periods[Int(maxFrozenPeriodIndex + 1)...Int(commonFrozenPeriodIndex - maxFrozenPeriodIndex)])
        // TODO: why is this not optional? does this return an empty array? see return statement

        maxFrozenPeriodIndex = commonFrozenPeriodIndex

        return result.count > 0 ? result : nil
    }

    ///
    func addLocation(location: CLLocation) {
        locations.append(location)
    }

    ///
    func addConnectivity(connectivity: RMBTConnectivity) { // -> computed property
        connectivities.append(connectivity)
    }

    ///
    func lastConnectivity() -> RMBTConnectivity! { // -> computed property
        return connectivities.last
    }

    ///
    func startDownloadWithThreadCount(threadCount: Int) {
        self.threadCount = threadCount

        perThreadDownloadHistories = NSMutableArray(capacity: threadCount)
        perThreadUploadHistories = NSMutableArray(capacity: threadCount)

        for _ in 0 ..< threadCount {
            perThreadDownloadHistories.addObject(RMBTThroughputHistory(resolutionNanos: resolutionNanos))
            perThreadUploadHistories.addObject(RMBTThroughputHistory(resolutionNanos: resolutionNanos))
        }

        totalCurrentHistory = totalDownloadHistory // TODO: check pass by value on array
        currentHistories = perThreadDownloadHistories // TODO: check pass by value on array
        maxFrozenPeriodIndex = -1
    }

    /// Per spec has same thread count as download
    func startUpload() {
        totalCurrentHistory = totalUploadHistory // TODO: check pass by value on array
        currentHistories = perThreadUploadHistories // TODO: check pass by value on array
        maxFrozenPeriodIndex = -1
    }

    /// Called at the end of each phase. Flushes out values to total history.
    func flush() -> [AnyObject]! {
        var result: [AnyObject]!// = [AnyObject]()

        for h in currentHistories {
            (h as! RMBTThroughputHistory).freeze()
        }

        result = updateTotalHistory()

        totalCurrentHistory.freeze()

        let totalPeriodCount = totalCurrentHistory.periods.count

        totalCurrentHistory.squashLastPeriods(1)

        // Squash last two periods in all histories
        for h in currentHistories {
            (h as! RMBTThroughputHistory).squashLastPeriods(1 + ((h as! RMBTThroughputHistory).periods.count - totalPeriodCount))
        }

        // Remove last measurement from result, as we don't want to plot that one as it's usually too short
        if result.count > 0 {
            result = Array(result[0..<(result.count - 1)])
        }

        return result
    }

    ///
    func resultDictionary() -> NSDictionary { // -> computed property
        let pingTestResultArray = pings.map { p in
            p.testResultDictionary()
        }

        var speedDetails = [[String:AnyObject]]()

        speedDetails += subresultForThreadThroughputs(perThreadDownloadHistories, withDirectionString: "download")
        speedDetails += subresultForThreadThroughputs(perThreadUploadHistories, withDirectionString: "upload")

        var result: [String:AnyObject] = [
            "test_ping_shortest":   NSNumber(unsignedLongLong: bestPingNanos),
            "pings":                pingTestResultArray,
            "speed_detail":         speedDetails,
            "test_num_threads":     NSNumber(unsignedInteger: UInt(threadCount))
        ]

        if TEST_USE_PERSONAL_DATA_FUZZING {
            result += ["publish_public_data": RMBTSettings.sharedSettings().publishPublicData]
            logger.info("test result: publish_public_data: \(RMBTSettings.sharedSettings().publishPublicData)")
        }

        result += subresultForTotalThroughput(totalDownloadHistory.totalThroughput, withDirectionString: "download")
        result += subresultForTotalThroughput(totalUploadHistory.totalThroughput, withDirectionString: "upload")
        result += locationsResultDictionary()
        result += connectivitiesResultDictionary()

        // add extended test statistics
        result += ["extended_test_stat": extendedTestStat]

        //logger.debug("TEST RESULT: \(result)")

        return result
    }

    ///
    private func subresultForThreadThroughputs(perThreadArray: /*[RMBTThroughputHistory]*/NSArray, withDirectionString directionString: String) -> [[String:AnyObject]] {
        var result = [[String:AnyObject]]()

        for i in 0 ..< perThreadArray.count {
            let h = perThreadArray.objectAtIndex(i)/*[i]*/ as! RMBTThroughputHistory
            var totalLength: UInt64 = 0

            for t in h.periods {
                totalLength += t.length

                result.append([
                    "direction": directionString,
                    "thread":   NSNumber(unsignedInteger: UInt(i)),
                    "time":     NSNumber(unsignedLongLong: t.endNanos),
                    "bytes":    NSNumber(unsignedLongLong: totalLength)
                ])
            }
        }

        return result
    }

    ///
    private func subresultForTotalThroughput(throughput: RMBTThroughput, withDirectionString directionString: String) -> [String:/*NSNumber*/AnyObject] {
        return [
            "test_speed_\(directionString)":    NSNumber(unsignedInt: throughput.kilobitsPerSecond()), // TODO: change kbps to computed property?
            "test_nsec_\(directionString)":     NSNumber(unsignedLongLong: throughput.endNanos),
            "test_bytes_\(directionString)":    NSNumber(unsignedLongLong: throughput.length)
        ]
    }

    ///
    private func locationsResultDictionary() -> [String:[[String:NSNumber]]] {
        var result = [[String:NSNumber]]()

        for l in locations {

            let t = l.timestamp.timeIntervalSinceDate(testStartDate) // t can be negative, if gps timestamp is before test start timestamp

            let tsNanos = Int64(t) * Int64(NSEC_PER_SEC)

            result.append([
                "geo_long": NSNumber(double: l.coordinate.longitude),
                "geo_lat":  NSNumber(double: l.coordinate.latitude),
                "tstamp":   NSNumber(unsignedLongLong: UInt64(l.timestamp.timeIntervalSince1970) * 1000),
                "time_ns":  NSNumber(longLong: tsNanos),
                "accuracy": NSNumber(double: l.horizontalAccuracy),
                "altitude": NSNumber(double: l.altitude),
                "speed":    NSNumber(double: (l.speed > 0.0) ? l.speed : 0.0)
            ])
        }

        return [
            "geoLocations": result
        ]
    }

    ///
    private func connectivitiesResultDictionary() -> [String:AnyObject] {
        var result = [String:AnyObject]()
        var signals = [[String:AnyObject]]()

        for c in connectivities {
            let cResult = c.testResultDictionary() as! [String:AnyObject]

            signals.append([
                "time": RMBTTimestampWithNSDate(c.timestamp),
                "network_type_id": cResult["network_type"]!
            ])

            if result.count == 0/* == nil*/ {
                //result = NSMutableDictionary(dictionary: cResult)
                //result = [String:AnyObject]()
                result += cResult
            } else {
                let previousNetworkType = result["network_type"]!.integerValue
                let currentNetworkType = cResult["network_type"]!.integerValue

                // Take maximum network type
                result["network_type"] = NSNumber(integer: max(previousNetworkType, currentNetworkType)) // TODO
                //result.setValue(NSNumber(integer: max(previousNetworkType, currentNetworkType)), forKey: "network_type")
            }
        }

        result["signals"] = signals // TODO
        //result.setValue(signals, forKey: "signals")

        return result
    }
}
