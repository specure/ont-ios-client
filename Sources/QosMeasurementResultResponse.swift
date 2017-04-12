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
open class QosMeasurementResultResponse: BasicResponse {

    ///
    open var evaluation: String?

    ///
    open var evalTimes: [String: Int]?

    ///
    open var testResultDetail: [MeasurementQosResult]?

    ///
    open var testResultDetailDescription: [MeasurementQosResultDetailDescription]?

    ///
    open var testResultDetailTestDescription: [MeasurementQosResultDetailTestDescription]?

    ///
    override open func mapping(map: Map) {
        super.mapping(map: map)

        evaluation <- map["evaluation"]
        evalTimes <- map["eval_times"]
        testResultDetail <- map["testresultdetail"]
        testResultDetailDescription <- map["testresultdetail_desc"]
        testResultDetailTestDescription <- map["testresultdetail_testdesc"]
    }

    ///
    open class MeasurementQosResult: Mappable {

        ///
        open var objectiveId: Int?

        ///
        open var type: QOSMeasurementType?

        ///
        open var successCount: Int?

        ///
        open var failureCount: Int?

        ///
        open var result: [String: AnyObject]?

        ///
        open var testDesc: String?

        ///
        open var summary: String?

        ///
        open var oldUid: Int?

        ///
        public init() {

        }

        ///
        required public init?(map: Map) {

        }

        ///
        open func mapping(map: Map) {
            objectiveId <- map["objectiveId"]
            type <- map["test_type"]
            successCount <- map["success_count"]
            failureCount <- map["failure_count"]
            result <- map["result"]
            testDesc <- map["test_desc"]
            summary <- map["test_summary"]
            oldUid <- map["uid"]
        }
    }

    ///
    open class MeasurementQosResultDetailDescription: Mappable {

        ///
        open var uid: [Int]?

        ///
        open var test: QOSMeasurementType?

        ///
        open var key: String?

        ///
        open var status: String?

        ///
        open var description: String?

        ///
        public init() {

        }

        ///
        required public init?(map: Map) {

        }

        ///
        open func mapping(map: Map) {
            uid <- map["uid"]
            test <- map["test"]
            key <- map["key"]
            status <- map["status"]
            description <- map["desc"]
        }
    }

    ///
    open class MeasurementQosResultDetailTestDescription: Mappable {

        ///
        open var name: String?

        ///
        open var type: QOSMeasurementType?

        ///
        open var description: String?

        ///
        public init() {

        }

        ///
        required public init?(map: Map) {

        }

        ///
        open func mapping(map: Map) {
            name <- map["name"]
            type <- map["test_type"]
            description <- map["desc"]
        }
    }
}
