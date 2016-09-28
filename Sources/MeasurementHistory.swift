/*****************************************************************************************************
 * Copyright 2016 SPECURE GmbH
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *****************************************************************************************************/

import Foundation
import RealmSwift
import ObjectMapper

///
public class MeasurementHistory {

    ///
    public static let sharedMeasurementHistory = MeasurementHistory()

    ///
    private let serialQueue = dispatch_queue_create(nil, DISPATCH_QUEUE_SERIAL)

    /// Set dirty to true if the history should be reloaded
    var dirty = true // dirty is true on app start // TODO: set this also after sync
    
    ///
    private init() {
        // TODO: remove realm test code
        // TODO: add migrations? at least look at how they work
        //_ = try? NSFileManager.defaultManager().removeItemAtURL(Realm.Configuration.defaultConfiguration.fileURL!) // delete db before during development
        
        if let realm = try? Realm() {
            let distinctNetworkTypes = Array(Set(realm.objects(StoredHistoryItem.self).valueForKey("networkType") as! [String]))
            let distinctModels = Array(Set(realm.objects(StoredHistoryItem.self).valueForKey("model") as! [String]))

            logger.debug("distinct network types: \(distinctNetworkTypes)")
            logger.debug("distinct models: \(distinctModels)")
        }
    }
    
    public func getHistoryFilterModel() -> [[String: AnyObject]] {
        var distinctNetworkTypes = [String]()
        var distinctModels = [String]()
        
        if let realm = try? Realm() {
            distinctNetworkTypes = Array(Set(realm.objects(StoredHistoryItem.self).valueForKey("networkType") as! [String]))
            distinctModels = Array(Set(realm.objects(StoredHistoryItem.self).valueForKey("model") as! [String]))
            
            logger.debug("distinct network types: \(distinctNetworkTypes)")
            logger.debug("distinct models: \(distinctModels)")
        }
        
        return [
            [
                "name": "network_type",
                "items": distinctNetworkTypes
            ],
            [
                "name": "model",
                "items": distinctModels
            ]
        ]
    }

    
    ///
    public func getHistoryList(success: (response: [HistoryItem]) -> (), error failure: ErrorCallback) {
        if !dirty { // return cached elements if not dirty
            // load items to view
            if let historyItems = self.getHistoryItems() {
                success(response: historyItems)
            } else {
                failure(error: NSError(domain: "didnt get history items", code: -12351223, userInfo: nil)) // TODO: call error callback if there were realm problems
            }
            
            return
        }
        
        dirty = false
        
        if let timestamp = getLastHistoryItemTimestamp() {
            logger.debug("timestamp!, requesting since \(timestamp)")

            ControlServer.sharedControlServer.getMeasurementHistory(UInt64(timestamp.timeIntervalSince1970), success: { historyItems in

                let serverUuidList = Set<String>(historyItems.map({ return $0.testUuid! })) // !
                let clientUuidList = Set<String>(self.getHistoryItemUuidList()!) // !
                
                logger.debug("server: \(serverUuidList)")
                logger.debug("client: \(clientUuidList)")

                let toRemove = clientUuidList.subtract(serverUuidList)
                let toAdd = serverUuidList.subtract(clientUuidList)

                logger.debug("to remove: \(toRemove)")
                logger.debug("to add: \(toAdd)")

                // add items
                self.insertOrUpdateHistoryItems(historyItems.filter({ return toAdd.contains($0.testUuid!) })) // !

                // remove items
                self.removeHistoryItems(toRemove)

                // load items to view
                if let historyItems = self.getHistoryItems() {
                    success(response: historyItems)
                } else {
                    failure(error: NSError(domain: "didnt get history items", code: -12351223, userInfo: nil)) // TODO: call error callback if there were realm problems
                }

            }, error: { error in // show cached items if this request fails
                
                // load items to view
                if let historyItems = self.getHistoryItems() {
                    success(response: historyItems)
                } else {
                    failure(error: NSError(domain: "didnt get history items", code: -12351223, userInfo: nil)) // TODO: call error callback if there were realm problems
                }
            })
        } else {
            logger.debug("database empty, requesting without timestamp")

            ControlServer.sharedControlServer.getMeasurementHistory({ historyItems in
                self.insertOrUpdateHistoryItems(historyItems)

                success(response: historyItems)
            }, error: failure)
        }
    }

    ///
    public func getHistoryList(filters: [[String: String]], success: (response: [HistoryItem]) -> (), error failure: ErrorCallback) {

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

    ///
    public func disassociateMeasurement(measurementUuid: String, success: (response: SpeedMeasurementDisassociateResponse) -> (), error failure: ErrorCallback) {
        ControlServer.sharedControlServer.disassociateMeasurement(measurementUuid, success: { response in
            logger.debug("DISASSOCIATE SUCCESS")

            // remove from db
            self.removeMeasurement(measurementUuid)
            
            success(response: response)

        }, error: failure)
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
    private func storeMeasurementData(uuid: String, measurement: SpeedMeasurementResultResponse) { // TODO: store google map static image in db?
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

    ///
    private func removeMeasurement(uuid: String) {
        if let realm = try? Realm() {
            do {
                try realm.write {
                    if let storedMeasurement = loadStoredMeasurement(uuid) {
                        realm.delete(storedMeasurement)
                    }
                
                    // remove also history item:
                    if let storedHistoryItem = loadStoredHistoryItem(uuid) {
                        realm.delete(storedHistoryItem)
                    }
                }
            } catch {
                logger.debug("realm error \(error)") // do nothing if fails?
            }
        }
    }

// MARK: HistoryItem

    ///
    private func loadStoredHistoryItem(uuid: String) -> StoredHistoryItem? {
        if let realm = try? Realm() {
            return realm.objects(StoredHistoryItem.self).filter("uuid == %@", uuid).first
        }

        return nil
    }

    ///
    private func getLastHistoryItemTimestamp() -> NSDate? {
        if let realm = try? Realm() {
            return realm.objects(StoredHistoryItem.self).max("timestamp")
        }

        return nil
    }
    
    ///
    private func getHistoryItems() -> [HistoryItem]? {
        if let realm = try? Realm() {
            let query = realm.objects(StoredHistoryItem.self).sorted("timestamp", ascending: false)
            
            return query.flatMap({ storedItem in
                logger.debug("\(storedItem.model)")
                logger.debug("\(storedItem.networkType)")
                
                return Mapper<HistoryItem>().map(storedItem.jsonData)
            })
        }
        
        return nil
    }
    
    ///
    private func getHistoryItems(filters: [String]) -> [HistoryItem]? {
        if let realm = try? Realm() {
            let query = realm.objects(StoredHistoryItem.self).filter("")
                
                .sorted("timestamp", ascending: false)
            
            return query.flatMap({ storedItem in
                logger.debug("\(storedItem.model)")
                logger.debug("\(storedItem.networkType)")
                
                return Mapper<HistoryItem>().map(storedItem.jsonData)
            })
        }
        
        return nil
    }

    ///
    private func getHistoryItemUuidList() -> [String]? {
        if let realm = try? Realm() {
            let uuidList = realm.objects(StoredHistoryItem.self).map({ storedItem in
                return storedItem.uuid! // !
            })

            return uuidList
        }

        return nil
    }

    ///
    private func insertOrUpdateHistoryItems(historyItems: [HistoryItem]) { // TODO: preload measurement, details and qos?
        if let realm = try? Realm() {
            do {
                try realm.write {
                    var storedHistoryItemList = [StoredHistoryItem]()

                    historyItems.forEach({ item in
                        //logger.debug("try to save history item: \(item)")

                        let storedHistoryItem = StoredHistoryItem()
                        storedHistoryItem.uuid = item.testUuid

                        storedHistoryItem.networkType = item.networkType
                        storedHistoryItem.model = item.model

                        storedHistoryItem.timestamp = NSDate(timeIntervalSince1970: Double(item.time!)) // !

                        storedHistoryItem.jsonData = Mapper<HistoryItem>().toJSONString(item)

                        storedHistoryItemList.append(storedHistoryItem)
                    })

                    logger.debug("storing \(storedHistoryItemList)")

                    realm.add(storedHistoryItemList)
                }
            } catch {
                logger.debug("realm error \(error)") // do nothing if fails?
            }
        }
    }

    ///
    private func removeHistoryItems(historyItemUuidList: Set<String>) {
        if let realm = try? Realm() {
            do {
                try realm.write {
                    realm.delete(realm.objects(StoredHistoryItem.self).filter("uuid IN %@", historyItemUuidList))
                }
            } catch {
                logger.debug("realm error \(error)") // do nothing if fails?
            }
        }
    }
    
}
