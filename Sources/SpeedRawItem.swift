//
//  SpeedRawItem.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 23.08.16.
//
//

import Foundation
import ObjectMapper

///
class SpeedRawItem: MeasurementSpeedRawItem {

    ///
    var direction: SpeedRawItemDirection?

    ///
    override func mapping(map: Map) {
        super.mapping(map)

        direction <- map["direction"]
    }

    ///
    enum SpeedRawItemDirection: String {
        case Download = "download"
        case Upload = "upload"
    }
}
