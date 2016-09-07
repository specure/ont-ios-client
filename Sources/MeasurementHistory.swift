//
//  MeasurementHistory.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 01.09.16.
//
//

import Foundation
import RealmSwift
import ObjectMapper

///
public class MeasurementHistory {

    ///
    public static let sharedMeasurementHistory = MeasurementHistory()

    ///
    private let serialQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL)

    ///
    private init() {
        // TODO: remove realm test code
        _ = try? NSFileManager.defaultManager().removeItemAtURL(Realm.Configuration.defaultConfiguration.fileURL!) // delete db before during development
    }

    ///
    public func getHistoryList() {

    }

    ///
    public func getHistoryList(filters: [[String: String]]) {

    }

    ///
    public func getMeasurement(uuid: String, success: (response: SpeedMeasurementResultResponse) -> (), error failure: ErrorCallback) {
        if let measurement = getStoredMeasurementData(uuid) {
            success(response: measurement)
            return
        }

        logger.debug("NEED TO LOAD MEASUREMENT \(uuid) FROM SERVER")

        ControlServer.sharedControlServer.getSpeedMeasurement(uuid, success: { response in

            // store measurement
            self.storeMeasurementData(uuid, measurement: response)

            success(response: response)
        }, error: failure)
    }

    ///
    public func getMeasurementDetails(uuid: String, success: (response: SpeedMeasurementDetailResultResponse) -> (), error failure: ErrorCallback) {
        if let measurementDetails = getStoredMeasurementDetailsData(uuid) {
            success(response: measurementDetails)
            return
        }

        logger.debug("NEED TO LOAD MEASUREMENT DETAILS \(uuid) FROM SERVER")

        ControlServer.sharedControlServer.getSpeedMeasurementDetails(uuid, success: { response in

            // store measurement details
            self.storeMeasurementDetailsData(uuid, measurementDetails: response)

            success(response: response)
        }, error: failure)
    }

    ///
    public func getQosMeasurement(uuid: String, success: (response: QosMeasurementResultResponse) -> (), error failure: ErrorCallback) {
        // Logic is different for qos (because the evaluation can change): load results every time and only return cached result if the request failed

        ControlServer.sharedControlServer.getQosMeasurement(uuid, success: { response in

            logger.debug("NEED TO LOAD MEASUREMENT QOS \(uuid) FROM SERVER (this is done every time since qos evaluation can be changed)")
            
            // store qos measurement
            self.storeMeasurementQosData(uuid, measurementQos: response)

            success(response: response)
        }, error: { error in
            if let measurementQos = self.getStoredMeasurementQosData(uuid) {
                success(response: measurementQos)
                return
            }

            failure(error: error)
        })
    }

// MARK: Get

    ///
    private func getStoredMeasurementData(uuid: String) -> SpeedMeasurementResultResponse? {
        if let storedMeasurement = loadStoredMeasurement(uuid) {
            if let measurementData = storedMeasurement.measurementData where measurementData.characters.count > 0 {
                if let measurement = Mapper<SpeedMeasurementResultResponse>().map(measurementData) {
                    logger.debug("RETURNING CACHED MEASUREMENT \(uuid)")
                    return measurement
                }
            }
        }

        return nil
    }

    ///
    private func getStoredMeasurementDetailsData(uuid: String) -> SpeedMeasurementDetailResultResponse? {
        if let storedMeasurement = loadStoredMeasurement(uuid) {
            if let measurementDetailsData = storedMeasurement.measurementDetailsData where measurementDetailsData.characters.count > 0 {
                if let measurementDetails = Mapper<SpeedMeasurementDetailResultResponse>().map(measurementDetailsData) {
                    logger.debug("RETURNING CACHED MEASUREMENT DETAILS \(uuid)")
                    return measurementDetails
                }
            }
        }

        return nil
    }

    ///
    private func getStoredMeasurementQosData(uuid: String) -> QosMeasurementResultResponse? {
        if let storedMeasurement = loadStoredMeasurement(uuid) {
            if let measurementQosData = storedMeasurement.measurementQosData where measurementQosData.characters.count > 0 {
                if let measurementQos = Mapper<QosMeasurementResultResponse>().map(measurementQosData) {
                    logger.debug("RETURNING CACHED QOS RESULT \(uuid)")
                    return measurementQos
                }
            }
        }

        return nil
    }

// MARK: Save

    ///
    private func storeMeasurementData(uuid: String, measurement: SpeedMeasurementResultResponse) {
        dispatch_async(serialQueue) {
            self.updateStoredMeasurement(uuid) { storedMeasurement in
                storedMeasurement.measurementData = Mapper<SpeedMeasurementResultResponse>().toJSONString(measurement)
            }
        }
    }

    ///
    private func storeMeasurementDetailsData(uuid: String, measurementDetails: SpeedMeasurementDetailResultResponse) {
        dispatch_async(serialQueue) {
            self.updateStoredMeasurement(uuid) { storedMeasurement in
                storedMeasurement.measurementDetailsData = Mapper<SpeedMeasurementDetailResultResponse>().toJSONString(measurementDetails)
            }
        }
    }

    ///
    private func storeMeasurementQosData(uuid: String, measurementQos: QosMeasurementResultResponse) {
        dispatch_async(serialQueue) {
            self.updateStoredMeasurement(uuid) { storedMeasurement in
                storedMeasurement.measurementQosData = Mapper<QosMeasurementResultResponse>().toJSONString(measurementQos)
            }
        }
    }

    ///
    private func loadStoredMeasurement(uuid: String) -> StoredMeasurement? {
        if let realm = try? Realm() {
            return realm.objects(StoredMeasurement.self).filter("uuid == %@", uuid).first
        }

        return nil
    }

    ///
    private func loadOrCreateStoredMeasurement(uuid: String) -> StoredMeasurement {
        if let storedMeasurement = loadStoredMeasurement(uuid) {
            return storedMeasurement
        }

        let storedMeasurement = StoredMeasurement()
        storedMeasurement.uuid = uuid

        return storedMeasurement
    }

    ///
    private func updateStoredMeasurement(uuid: String, updateBlock: (storedMeasurement: StoredMeasurement) -> ()) {
        if let realm = try? Realm() {
            do {
                try realm.write {
                    let storedMeasurement = self.loadOrCreateStoredMeasurement(uuid)

                    updateBlock(storedMeasurement: storedMeasurement)

                    realm.add(storedMeasurement)
                }
            } catch {
                logger.debug("realm error \(error)") // do nothing if fails?
            }
        }
    }
}
