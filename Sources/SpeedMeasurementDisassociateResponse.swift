//
//  SpeedMeasurementDisassociateResponse.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 23.08.16.
//
//

import Foundation
import ObjectMapper

///
public class SpeedMeasurementDisassociateResponse: BasicResponse {

    ///
    public var success = false

    ///
    override public func mapping(map: Map) {
        super.mapping(map)

        success <- map["success"]
    }
}
