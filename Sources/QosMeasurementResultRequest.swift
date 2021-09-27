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
class QosMeasurementResultRequest: BasicRequest {

    ///
    var measurementUuid: String?

    ///
    var clientUuid: String?

    ///
    var testToken: String?

    ///
    var time: UInt64?

    ///
    var qosResultList: [QOSTestResults]?

    ///
    override func mapping(map: Map) {
        super.mapping(map: map)

        measurementUuid <- map["uuid"]
        testToken       <- map["test_token"]
        clientUuid      <- map["client_uuid"]
        time            <- (map["time"], UInt64NSNumberTransformOf)
        qosResultList   <- map["qos_result"]
    }
    
    /*
     {
       "test_token": "string",
       "client_uuid": "string",
       "time": 0,
       "client_version": "string",
       "qos_result": [
         {
           "test_type": "string",
           "qosTestUid": 0,
           "durationNs": 0,
           "startTimeNs": 0
         }
       ],
       "client_name": "string",
       "client_language": "string"
     }
     */
}
