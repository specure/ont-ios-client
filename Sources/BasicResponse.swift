//
//  BasicResponse.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 23.08.16.
//
//

import Foundation
import ObjectMapper

///
public class BasicResponse: Mappable, CustomStringConvertible {

    ///
    public var description: String {
        return "<empty BasicResponse>"
    }

    ///
    public init() {

    }

    ///
    required public init?(_ map: Map) {

    }

    ///
    public func mapping(map: Map) {

    }
}
