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

///
open class MeasurementHistory {

    ///
    public static let sharedMeasurementHistory = MeasurementHistory()

    ///
    private let serialQueue = DispatchQueue(label: "DefaultHistoryQueue", attributes: [])

    /// Set dirty to true if the history should be reloaded
    var dirty = true // dirty is true on app start // TODO: set this also after sync
    
    ///
    private init() {
        // TODO: remove realm test code
        // TODO: add migrations? at least look at how they work
        //_ = try? NSFileManager.defaultManager().removeItemAtURL(Realm.Configuration.defaultConfiguration.fileURL!) // delete db before during development
        
        /*if let realm = try? Realm() {
            let distinctNetworkTypes = Array(Set(realm.objects(StoredHistoryItem.self).valueForKey("networkType") as! [String]))
            let distinctModels = Array(Set(realm.objects(StoredHistoryItem.self).valueForKey("model") as! [String]))

            Log.logger.debug("distinct network types: \(distinctNetworkTypes)")
            Log.logger.debug("distinct models: \(distinctModels)")
            
            Log.logger.debug("COUNT1: \(realm.objects(StoredHistoryItem.self).filter("model IN %@", distinctModels).count)")
            Log.logger.debug("COUNT2: \(realm.objects(StoredHistoryItem.self).filter("model IN %@", [distinctModels.first!]).count)")
            Log.logger.debug("COUNT3: \(realm.objects(StoredHistoryItem.self).filter("model IN %@", [distinctModels.last!]).count)")
        }*/
    }
    
    open func getHistoryFilterModel() -> [[String: AnyObject]] {
        var distinctNetworkTypes = [String]()
        var distinctModels = [String]()
        
        if let realm = try? Realm() {
            distinctNetworkTypes = Array(Set(realm.objects(StoredHistoryItem.self).value(forKey: "networkType") as! [String]))
            distinctModels = Array(Set(realm.objects(StoredHistoryItem.self).value(forKey: "model") as! [String]))
            
            Log.logger.debug("distinct network types: \(distinctNetworkTypes)")
            Log.logger.debug("distinct models: \(distinctModels)")
        }
        
        return [
            [
                "name": "network_type" as AnyObject,
                "items": distinctNetworkTypes as AnyObject
            ],
            [
                "name": "model" as AnyObject,
                "items": distinctModels as AnyObject
            ]
        ]
    }

    ///
    open func getHistoryList(_ filters: HistoryFilterType, success: @escaping (_ response: [HistoryItem]) -> (), error failure: @escaping ErrorCallback) {
        if !dirty { // return cached elements if not dirty
            // load items to view
            if let historyItems = self.getHistoryItems(filters) {
                success(historyItems)
            } else {
                failure(NSError(domain: "didnt get history items", code: -12351223, userInfo: nil)) // TODO: call error callback if there were realm problems
            }
            
            return
        }
        
        dirty = false
        
        if let timestamp = getLastHistoryItemTimestamp() {
            Log.logger.debug("timestamp!, requesting since \(timestamp)")

            ControlServer.sharedControlServer.getMeasurementHistory(UInt64(timestamp.timeIntervalSince1970), success: { historyItems in

                let serverUuidList = Set<String>(historyItems.map({ return $0.testUuid! })) // !
                let clientUuidList = Set<String>(self.getHistoryItemUuidList()!) // !
                
                Log.logger.debug("server: \(serverUuidList)")
                Log.logger.debug("client: \(clientUuidList)")

                let toRemove = clientUuidList.subtracting(serverUuidList)
                let toAdd = serverUuidList.subtracting(clientUuidList)

                Log.logger.debug("to remove: \(toRemove)")
                Log.logger.debug("to add: \(toAdd)")

                // add items
                self.insertOrUpdateHistoryItems(historyItems.filter({ return toAdd.contains($0.testUuid!) })) // !

                // remove items
                self.removeHistoryItems(toRemove)

                // load items to view
                if let historyItems = self.getHistoryItems(filters) {
                    success(historyItems)
                } else {
                    failure(NSError(domain: "didnt get history items", code: -12351223, userInfo: nil)) // TODO: call error callback if there were realm problems
                }

            }, error: { error in // show cached items if this request fails
                
                // load items to view
                if let historyItems = self.getHistoryItems(filters) {
                    success(historyItems)
                } else {
                    failure(NSError(domain: "didnt get history items", code: -12351223, userInfo: nil)) // TODO: call error callback if there were realm problems
                }
            })
        } else {
            Log.logger.debug("database empty, requesting without timestamp")

            ControlServer.sharedControlServer.getMeasurementHistory({ historyItems in
                self.insertOrUpdateHistoryItems(historyItems)

                if let dbHistoryItems = self.getHistoryItems(filters) {
                    success(dbHistoryItems)
                } else {
                    success(historyItems)
                }
            }, error: failure)
        }
    }

    ///
    open func getMeasurement(_ uuid: String, success: @escaping (_ response: SpeedMeasurementResultResponse) -> (), error failure: @escaping ErrorCallback) {
        if let measurement = getStoredMeasurementData(uuid) {
            success(measurement)
            return
        }

        Log.logger.debug("NEED TO LOAD MEASUREMENT \(uuid) FROM SERVER")

        ControlServer.sharedControlServer.getSpeedMeasurement(uuid, success: { response in

            // store measurement
            self.storeMeasurementData(uuid, measurement: response)

            success(response)
        }, error: failure)
    }
    
    ///
    open func getQOSHistoryOld(uuid:String, success: @escaping (_ response: QosMeasurementResultResponse) -> (), error failure: @escaping ErrorCallback) {
    
        ControlServer.sharedControlServer.getQOSHistoryResultWithUUID(testUuid: uuid, success: { response in
            
            
            
            success(response)
        }, error: failure)
    }
    
    ///
    open func getMeasurementDetails_Old(_ uuid: String, full:Bool, success: @escaping (_ response: MapMeasurementResponse_Old) -> (), error failure: @escaping ErrorCallback) {

        
        
        Log.logger.debug("NEED TO LOAD MEASUREMENT DETAILS \(uuid) FROM SERVER")
        
        ControlServer.sharedControlServer.getHistoryResultWithUUID(uuid: uuid, fullDetails:full,  success: { response in
            
            
            success(response)
        }, error: failure)
    }

    ///
    open func getMeasurementDetails(_ uuid: String, success: @escaping (_ response: SpeedMeasurementDetailResultResponse) -> (), error failure: @escaping ErrorCallback) {
        if let measurementDetails = getStoredMeasurementDetailsData(uuid) {
            success(measurementDetails)
            return
        }

        Log.logger.debug("NEED TO LOAD MEASUREMENT DETAILS \(uuid) FROM SERVER")

        ControlServer.sharedControlServer.getSpeedMeasurementDetails(uuid, success: { response in

            // store measurement details
            self.storeMeasurementDetailsData(uuid, measurementDetails: response)

            success(response)
        }, error: failure)
    }

    ///
    open func getQosMeasurement(_ uuid: String, success: @escaping (_ response: QosMeasurementResultResponse) -> (), error failure: @escaping ErrorCallback) {
        // Logic is different for qos (because the evaluation can change): load results every time and only return cached result if the request failed

        ControlServer.sharedControlServer.getQosMeasurement(uuid, success: { response in

            Log.logger.debug("NEED TO LOAD MEASUREMENT QOS \(uuid) FROM SERVER (this is done every time since qos evaluation can be changed)")

            // store qos measurement
            self.storeMeasurementQosData(uuid, measurementQos: response)

            success(response)
        }, error: { error in
            if let measurementQos = self.getStoredMeasurementQosData(uuid) {
                success(measurementQos)
                return
            }

            failure(error)
        })
    }

    ///
    open func disassociateMeasurement(_ measurementUuid: String, success: @escaping (_ response: SpeedMeasurementDisassociateResponse) -> (), error failure: @escaping ErrorCallback) {
        ControlServer.sharedControlServer.disassociateMeasurement(measurementUuid, success: { response in
            Log.logger.debug("DISASSOCIATE SUCCESS")

            // remove from db
            self.removeMeasurement(measurementUuid)
            
            success(response)

        }, error: failure)
    }
    
    /// OLD history
    open func getHistoryWithFilters(filters: HistoryFilterType?, length: UInt, offset: UInt, success: @escaping (_ response: HistoryWithFiltersResponse) -> (), error errorCallback: @escaping ErrorCallback) {
        ControlServer.sharedControlServer.getHistoryWithFilters(filters: filters, length: length, offset: offset, success: success, error: errorCallback)
    }
    
    ///
    open func syncDevicesWith(code:String, success : @escaping (_ response: SyncCodeResponse) -> (), error failure: @escaping ErrorCallback) {
        ControlServer.sharedControlServer.syncWithCode(code: code, success: success, error: failure)
    
    }
    
    ///
    open func getSyncCode(success : @escaping (_ response: GetSyncCodeResponse) -> (), error failure: @escaping ErrorCallback) {
        ControlServer.sharedControlServer.synchGetCode(success: success, error: failure)
    }

// MARK: Get

    ///
    fileprivate func getStoredMeasurementData(_ uuid: String) -> SpeedMeasurementResultResponse? {
        if let storedMeasurement = loadStoredMeasurement(uuid) {
            if let measurementData = storedMeasurement.measurementData, measurementData.count > 0 {
                if let measurement = Mapper<SpeedMeasurementResultResponse>().map(JSONString:measurementData) {
                    Log.logger.debug("RETURNING CACHED MEASUREMENT \(uuid)")
                    return measurement
                }
            }
        }

        return nil
    }

    ///
    fileprivate func getStoredMeasurementDetailsData(_ uuid: String) -> SpeedMeasurementDetailResultResponse? {
        if let storedMeasurement = loadStoredMeasurement(uuid) {
            if let measurementDetailsData = storedMeasurement.measurementDetailsData, measurementDetailsData.count > 0 {
                if let measurementDetails = Mapper<SpeedMeasurementDetailResultResponse>().map(JSONString:measurementDetailsData) {
                    Log.logger.debug("RETURNING CACHED MEASUREMENT DETAILS \(uuid)")
                    return measurementDetails
                }
            }
        }

        return nil
    }

    ///
    fileprivate func getStoredMeasurementQosData(_ uuid: String) -> QosMeasurementResultResponse? {
        if let storedMeasurement = loadStoredMeasurement(uuid) {
            if let measurementQosData = storedMeasurement.measurementQosData, measurementQosData.count > 0 {
                if let measurementQos = Mapper<QosMeasurementResultResponse>().map(JSONString:measurementQosData) {
                    Log.logger.debug("RETURNING CACHED QOS RESULT \(uuid)")
                    return measurementQos
                }
            }
        }

        return nil
    }

// MARK: Save

    ///
    fileprivate func storeMeasurementData(_ uuid: String, measurement: SpeedMeasurementResultResponse) { // TODO: store google map static image in db?
        (serialQueue).async {
            self.updateStoredMeasurement(uuid) { storedMeasurement in
                storedMeasurement.measurementData = Mapper<SpeedMeasurementResultResponse>().toJSONString(measurement)
            }
        }
    }

    ///
    fileprivate func storeMeasurementDetailsData(_ uuid: String, measurementDetails: SpeedMeasurementDetailResultResponse) {
        (serialQueue).async {
            self.updateStoredMeasurement(uuid) { storedMeasurement in
                storedMeasurement.measurementDetailsData = Mapper<SpeedMeasurementDetailResultResponse>().toJSONString(measurementDetails)
            }
        }
    }

    ///
    fileprivate func storeMeasurementQosData(_ uuid: String, measurementQos: QosMeasurementResultResponse) {
        (serialQueue).async {
            self.updateStoredMeasurement(uuid) { storedMeasurement in
                storedMeasurement.measurementQosData = Mapper<QosMeasurementResultResponse>().toJSONString(measurementQos)
            }
        }
    }

    ///
    fileprivate func loadStoredMeasurement(_ uuid: String) -> StoredMeasurement? {
        if let realm = try? Realm() {
            return realm.objects(StoredMeasurement.self).filter("uuid == %@", uuid).first
        }

        return nil
    }

    ///
    fileprivate func loadOrCreateStoredMeasurement(_ uuid: String) -> StoredMeasurement {
        if let storedMeasurement = loadStoredMeasurement(uuid) {
            return storedMeasurement
        }

        let storedMeasurement = StoredMeasurement()
        storedMeasurement.uuid = uuid

        return storedMeasurement
    }

    ///
    fileprivate func updateStoredMeasurement(_ uuid: String, updateBlock: (_ storedMeasurement: StoredMeasurement) -> ()) {
        if let realm = try? Realm() {
            do {
                try realm.write {
                    let storedMeasurement = self.loadOrCreateStoredMeasurement(uuid)

                    updateBlock(storedMeasurement)

                    realm.add(storedMeasurement)
                }
            } catch {
                Log.logger.debug("realm error \(error)") // do nothing if fails?
            }
        }
    }

    ///
    fileprivate func removeMeasurement(_ uuid: String) {
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
                Log.logger.debug("realm error \(error)") // do nothing if fails?
            }
        }
    }

// MARK: HistoryItem

    ///
    fileprivate func loadStoredHistoryItem(_ uuid: String) -> StoredHistoryItem? {
        if let realm = try? Realm() {
            return realm.objects(StoredHistoryItem.self).filter("uuid == %@", uuid).first
        }

        return nil
    }

    ///
    fileprivate func getLastHistoryItemTimestamp() -> Date? {
        if let realm = try? Realm() {
            return realm.objects(StoredHistoryItem.self).max(ofProperty: "timestamp")
        }

        return nil
    }
    
    ///
    fileprivate func getHistoryItems(_ filters: HistoryFilterType) -> [HistoryItem]? {
        if let realm = try? Realm() {
            var query = realm.objects(StoredHistoryItem.self)
            
            if !filters.isEmpty {
                Log.logger.debug("filters: \(filters)")
                
                for (filterColumn, filterEntries) in filters {
                    query = query.filter("\(filterColumn) IN %@", filterEntries)
                }
            }
            
            query = query.sorted(byKeyPath: "timestamp", ascending: false)
            
            return query.compactMap({ storedItem in
                Log.logger.debug("\(String(describing: storedItem.model))")
                Log.logger.debug("\(String(describing: storedItem.networkType))")
                
                return Mapper<HistoryItem>().map(JSONString:storedItem.jsonData!)
            })
        }
        
        return nil
    }

    ///
    fileprivate func getHistoryItemUuidList() -> [String]? {
        if let realm = try? Realm() {
            let uuidList = realm.objects(StoredHistoryItem.self).map({ storedItem in
                return storedItem.uuid! // !
            })

            return Array(uuidList)
        }

        return nil
    }

    ///
    fileprivate func insertOrUpdateHistoryItems(_ historyItems: [HistoryItem]) { // TODO: preload measurement, details and qos?
        if let realm = try? Realm() {
            do {
                try realm.write {
                    var storedHistoryItemList = [StoredHistoryItem]()

                    historyItems.forEach({ item in
                        //Log.logger.debug("try to save history item: \(item)")

                        let storedHistoryItem = StoredHistoryItem()
                        storedHistoryItem.uuid = item.testUuid

                        storedHistoryItem.networkType = item.networkType
                        
                        storedHistoryItem.model = item.model
                        
                        if let t = item.time {
                            storedHistoryItem.timestamp = NSDate(timeIntervalSince1970: Double(t)) as Date
                        }
                        
                        storedHistoryItem.jsonData = Mapper<HistoryItem>().toJSONString(item)

                        storedHistoryItemList.append(storedHistoryItem)
                    })

                    Log.logger.debug("storing \(storedHistoryItemList)")

                    realm.add(storedHistoryItemList)
                }
            } catch {
                Log.logger.debug("realm error \(error)") // do nothing if fails?
            }
        }
    }

    ///
    fileprivate func removeHistoryItems(_ historyItemUuidList: Set<String>) {
        if let realm = try? Realm() {
            do {
                try realm.write {
                    realm.delete(realm.objects(StoredHistoryItem.self).filter("uuid IN %@", historyItemUuidList))
                }
            } catch {
                Log.logger.debug("realm error \(error)") // do nothing if fails?
            }
        }
    }
    
}
