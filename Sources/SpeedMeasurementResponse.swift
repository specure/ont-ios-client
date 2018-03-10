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
import ObjectMapper

///
open class SpeedMeasurementResponse: BasicResponse {

    ///
    open var testToken: String?

    ///
    open var testUuid: String?

    ///
    open var clientRemoteIp: String?

    ///
    var duration: Double = 7 // TODO: int instead of double?

    ///
    var pretestDuration: Double = RMBT_TEST_PRETEST_DURATION_S // TODO: int instead of double?

    ///
    var pretestMinChunkCountForMultithreading: Int = RMBT_TEST_PRETEST_MIN_CHUNKS_FOR_MULTITHREADED_TEST

    ///
    var numThreads: Int = 3

    ///
    var numPings: Int = 10

    ///
    var testWait: Double = 0 // TODO: int instead of double?

    ///
    open var measurementServer: TargetMeasurementServer?
    
    ///
    open func add(details:TargetMeasurementServer) {
        self.measurementServer = details
    }

    ///
    override open func mapping(map: Map) {
        super.mapping(map: map)

        testToken           <- map["test_token"]
        testUuid            <- map["test_uuid"]

        clientRemoteIp      <- map["client_remote_ip"]
        duration            <- map["duration"]
        pretestDuration     <- map["duration_pretest"]
        numThreads          <- map["num_threads"]
        numPings            <- map["num_pings"]
        testWait            <- map["test_wait"]
        measurementServer   <- map["target_measurement_server"]

    }

    ///
    override open var description: String {
        return "SpeedMeasurmentResponse: testToken: \(String(describing: testToken)), testUuid: \(String(describing: testUuid)), clientRemoteIp: \n\(String(describing: clientRemoteIp))"
    }
    
    class func createAndFill(from response: SpeedMeasurementResponse_Old) -> SpeedMeasurementResponse {
        let r = SpeedMeasurementResponse()
        r.clientRemoteIp = response.clientRemoteIp
        r.duration = response.duration
        r.pretestDuration = response.pretestDuration
        r.numPings = Int(response.numPings)!
        r.numThreads = Int(response.numThreads)!
        r.testToken = response.testToken
        r.testUuid = response.testUuid

        let measure = TargetMeasurementServer()
        measure.port = response.port?.intValue
        measure.address = response.serverAddress
        measure.name = response.serverName
        measure.encrypted = response.serverEncryption
        measure.uuid = response.testUuid
        
        r.add(details:measure)
        
        return r
    }
}

///
open class TargetMeasurementServer: Mappable {
    
    ///
    var address: String?
    
    ///
    var encrypted = false
    
    ///
    open var name: String?
    
    ///
    var port: Int?
    
    ///
    var uuid: String?
    
    ///
    var ip: String? // TODO: drop this?
    
    ///
    init() {
        
    }
    
    ///
    required public init?(map: Map) {
        
    }
    
    ///
    open func mapping(map: Map) {
        address     <- map["address"]
        encrypted   <- map["is_encrypted"]
        name        <- map["name"]
        port        <- map["port"]
        uuid        <- map["uuid"]
        ip          <- map["ip"]
    }
}
