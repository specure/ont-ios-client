//
//  MapMeasurementResponse.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 23.08.16.
//
//

import Foundation
import ObjectMapper

///
public class MapMeasurementResponse: BasicResponse {

    ///
    var measurements: [SpeedMeasurementResultResponse]?

    ///
    override public func mapping(map: Map) {
        super.mapping(map)

        measurements <- map["measurements"]
    }
}
