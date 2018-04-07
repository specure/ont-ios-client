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
class StoredZeroMeasurement: Object {

// MARK: Data

    ///
    @objc dynamic var measurementData: String?
    
    @objc dynamic var uuid: String?
    
    class func storedZeroMeasurement(with measurement: SpeedMeasurementResult) -> StoredZeroMeasurement {
        let storedZeroMeasurement = StoredZeroMeasurement()
        storedZeroMeasurement.uuid = UUID().uuidString
        
        storedZeroMeasurement.measurementData = Mapper().toJSONString(measurement)
        
        return storedZeroMeasurement
    }
    
    func store() {
        if let realm = try? Realm() {
            do {
                try realm.write {
                    realm.add(self)
                }
            } catch {
                Log.logger.debug("realm error \(error)") // do nothing if fails?
            }
        }
    }

    func deleteObject() {
        if let realm = try? Realm(),
            let uuid = self.uuid {
            do {
                try realm.write {
                    realm.delete(realm.objects(StoredZeroMeasurement.self).filter("uuid = %@", uuid))
                }
            } catch {
                Log.logger.debug("realm error \(error)") // do nothing if fails?
            }
        }
    }
    
    func speedMeasurementResult() -> SpeedMeasurementResult? {
        guard let data = self.measurementData else { return nil }
        
        let map = Mapper<SpeedMeasurementResult>().map(JSONString: data)
        return map
    }
    
    class func loadObjects() -> [StoredZeroMeasurement]? {
        if let realm = try? Realm() {
            return Array(realm.objects(StoredZeroMeasurement.self))
        }
        return nil
    }
}
