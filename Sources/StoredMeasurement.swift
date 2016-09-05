//
//  StoredMeasurement.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 01.09.16.
//
//

import Foundation
import RealmSwift
import ObjectMapper

///
class StoredMeasurement: Object {

    ///
    dynamic var uuid: String?

// MARK: Filterable things

    ///
    dynamic var networkType: String?

    ///
    dynamic var device: String?

// MARK: Data

    ///
    dynamic var measurementData: String?

    ///
    dynamic var measurementDetailsData: String?

    ///
    dynamic var measurementQosData: String?

    //

    ///
    override static func primaryKey() -> String? {
        return "uuid"
    }
}
