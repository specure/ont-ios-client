//
//  StoredHistoryItem.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 01.09.16.
//
//

import Foundation
import RealmSwift
import ObjectMapper

///
class StoredHistoryItem: Object {

    ///
    dynamic var uuid: String?

// MARK: Filterable data

    ///
    dynamic var networkType: String?

    ///
    dynamic var model: String?

// MARK: Data

    ///
    dynamic var timestamp: NSDate?

    ///
    dynamic var jsonData: String?

    //

    ///
    override static func primaryKey() -> String? {
        return "uuid"
    }
}
