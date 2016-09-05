//
//  MeasurementHistory.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 01.09.16.
//
//

import Foundation
import RealmSwift

///
public class MeasurementHistory {

    ///
    public static let sharedMeasurementHistory = MeasurementHistory()

    ///
    private let realm: Realm?

    ///
    private init() {
        // TODO: remove realm test code
        _ = try? NSFileManager.defaultManager().removeItemAtURL(Realm.Configuration.defaultConfiguration.fileURL!) // delete db before during development
        do {
            realm = try? Realm()

            let a = realm?.objects(StoredMeasurement.self).filter("uuid == %@ AND device == %@", "TEST", "abc")
            logger.debug("realm: \(a?.count)")

            let test = StoredMeasurement()
            test.uuid = "TEST"

            test.device = "abc"

            try realm?.write {
                realm?.add(test)
            }

            logger.debug("realm: \(a?.count)")

        } catch {
            logger.debug("realm error \(error)")
        }
    }

    public func getHistoryList() {

    }

    ///
    public func getHistoryList(filters: [[String: String]]) {

    }

    ///
    public func getMeasurement(uuid: String) -> SpeedMeasurementResultResponse? {

        return nil
    }

    ///
    public func getMeasurementDetails(uuid: String) -> SpeedMeasurementResultResponse? {

        return nil
    }

    ///
    public func getQosMeasurement(uuid: String) -> SpeedMeasurementResultResponse? {

        return nil
    }
}
