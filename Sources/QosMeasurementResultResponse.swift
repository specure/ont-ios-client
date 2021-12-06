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
    
    /// calculate success/failure percentage
    open func calculateQosSuccessPercentage() -> Float {
        var successCount = 0
        
        if let testResultDetail = self.testResultDetail, testResultDetail.count > 0 {
            for result in testResultDetail {
                if let failureCount = result.failureCount, failureCount == 0 {
                    successCount += 1
                }
            }
            
            let percentage = 100.0 * Float(successCount) / Float(testResultDetail.count)
            
            return percentage
        }
        return 0.0
    }
    
    open func calculateQosSuccessPercentage() -> String? {
        if let testResultDetail = self.testResultDetail, testResultDetail.count > 0 {
            let successCount = self.calculateQosSuccess()
            let percent: Float = self.calculateQosSuccessPercentage()
            let testResultDetailCount = testResultDetail.count
            Log.logger.info("QOS INFO: \(percent)")
            return String(format: "%0.0f%% (%i/%i)", percent, successCount, testResultDetailCount)
        }
        else {
            Log.logger.error("NO QOS testResultDetail")
            return nil
        }
    }
    
    open func calculateQosSuccess() -> Int {
        var successCount = 0
        
        if let testResultDetail = self.testResultDetail, testResultDetail.count > 0 {
            for result in testResultDetail {
                if let failureCount = result.failureCount, failureCount == 0 {
                    successCount += 1
                }
            }
        }
        
        return successCount
    }
    
    open func calculateQosFailed() -> Int {
        let failedCount = (self.testResultDetail?.count ?? 0) - self.calculateQosSuccess()
        return failedCount
    }

    ///
    open class MeasurementQosResult: Mappable {

        ///
        open var objectiveId: Int = 0

        ///
        open var type: QosMeasurementType?
        
        ///
        open var reconType:String?

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
            //type <- map["test_type"]
            reconType <- map["test_type"]
            type = QosMeasurementType(rawValue: (reconType?.lowercased())!)
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
        open var test: QosMeasurementType?

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
        open var type: QosMeasurementType?

        ///
        open var description: String?
        
        /// can be deleted when consolidated
        var reconType:String?

        ///
        public init() {

        }

        ///
        required public init?(map: Map) {

        }

        ///
        open func mapping(map: Map) {
            name <- map["name"]
            // type <- map["test_type"]
            ///
            reconType <- map["test_type"]
            type = QosMeasurementType(rawValue: (reconType?.lowercased())!)
            ///
            description <- map["desc"]
        }
    }
}
