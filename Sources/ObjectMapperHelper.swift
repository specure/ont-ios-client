//
//  ObjectMapperHelper.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 06.09.16.
//
//

import Foundation
import ObjectMapper

///
let UInt64NSNumberTransformOf = TransformOf<UInt64, NSNumber>(fromJSON: { $0?.unsignedLongLongValue }, toJSON: { $0.map { NSNumber(unsignedLongLong: $0) } })
