//
//  MeasurementSpeedRawItem.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 23.08.16.
//
//

import Foundation
import ObjectMapper

///
class MeasurementSpeedRawItem: Mappable {

    ///
    var thread: Int?

    ///
    var time: UInt64?

    ///
    var bytes: UInt64?

    ///
    init() {

    }

    ///
    required init?(_ map: Map) {

    }

    ///
    func mapping(map: Map) {
        thread  <- map["thread"]
        time    <- (map["time"], UInt64NSNumberTransformOf)
        bytes   <- (map["bytes"], UInt64NSNumberTransformOf)
    }
}
