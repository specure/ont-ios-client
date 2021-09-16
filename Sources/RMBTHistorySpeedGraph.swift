//
//  RMBTHistorySpeedGraph.swift
//  RMBTClient
//
//  Created by Sergey Glushchenko on 05.07.2021.
//

import Foundation
import ObjectMapper

public final class RMBTHistorySpeedGraph: BasicResponse {

    public final class RMBTSpeedTick: NSObject, Mappable {
        var bytesTotal: UInt64 = 0
        var timeElapsed: UInt64 = 0
        
        public init?(map: Map) { }

        public func mapping(map: Map) {
            bytesTotal <- map["bytes_total"]
            timeElapsed <- map["time_elapsed"]
        }
    }
    
    public var downloadThroughputs: [RMBTThroughput] {
        var t: UInt64 = 0
        var bytes: UInt64 = 0
        return downloadTicks.map({
            let end = $0.timeElapsed * NSEC_PER_MSEC
            let deltaBytes = $0.bytesTotal - bytes
            let result = RMBTThroughput(length: deltaBytes, startNanos: t, endNanos: end)
            t = end
            bytes += deltaBytes
            return result
        })
    }
    
    public var uploadThroughputs: [RMBTThroughput] {
        var t: UInt64 = 0
        var bytes: UInt64 = 0
        return uploadTicks.map({
            let end = $0.timeElapsed * NSEC_PER_MSEC
            let deltaBytes = $0.bytesTotal - bytes
            let result = RMBTThroughput(length: deltaBytes, startNanos: t, endNanos: end)
            t = end
            bytes += deltaBytes
            return result
        })
    }

    public var downloadTicks: [RMBTSpeedTick] = []
    public var uploadTicks: [RMBTSpeedTick] = []
    
    ///
    public override func mapping(map: Map) {
        super.mapping(map: map)
        downloadTicks <- map["speed_curve.download"]
        uploadTicks <- map["speed_curve.upload"]
    }
}
