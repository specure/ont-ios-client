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
class QosMeasurmentResponse: BasicResponse {

    ///
    var testToken: String?

    ///
    var testUuid: String?

    ///
    var objectives: [String: [[String: AnyObject]]]?

    ///
    override func mapping(map: Map) {
        super.mapping(map: map)

        testToken <- map["test_token"]
        testUuid <- map["test_uuid"]

        objectives <- map["objectives"]
    }

    ///
    override var description: String {
        return "QosMeasurmentResponse: testToken: \(String(describing: testToken)), testUuid: \(String(describing: testUuid)), objectives: \n\(String(describing: objectives))"
    }
}
