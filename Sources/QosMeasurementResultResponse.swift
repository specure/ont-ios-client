//
//  QosMeasurementResultResponse.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 23.08.16.
//
//

import Foundation
import ObjectMapper

///
public class QosMeasurementResultResponse: BasicResponse {

    ///
    public var evaluation: String?

    ///
    public var evalTimes: [String: Int]?

    ///
    public var testResultDetail: [MeasurementQosResult]?

    ///
    public var testResultDetailDescription: [MeasurementQosResultDetailDescription]?

    ///
    public var testResultDetailTestDescription: [MeasurementQosResultDetailTestDescription]?

    ///
    override public func mapping(map: Map) {
        super.mapping(map)

        evaluation <- map["evaluation"]
        evalTimes <- map["eval_times"]
        testResultDetail <- map["testresultdetail"]
        testResultDetailDescription <- map["testresultdetail_desc"]
        testResultDetailTestDescription <- map["testresultdetail_testdesc"]
    }

    ///
    public class MeasurementQosResult: Mappable {

        ///
        public var objectiveId: Int?

        ///
        public var type: QOSMeasurementType?

        ///
        public var successCount: Int?

        ///
        public var failureCount: Int?

        ///
        public var result: [String: AnyObject]?

        ///
        public var testDesc: String?

        ///
        public var summary: String?

        ///
        public var oldUid: Int?

        ///
        public init() {

        }

        ///
        required public init?(_ map: Map) {

        }

        ///
        public func mapping(map: Map) {
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
    public class MeasurementQosResultDetailDescription: Mappable {

        ///
        public var uid: [Int]?

        ///
        public var test: QOSMeasurementType?

        ///
        public var key: String?

        ///
        public var status: String?

        ///
        public var description: String?

        ///
        public init() {

        }

        ///
        required public init?(_ map: Map) {

        }

        ///
        public func mapping(map: Map) {
            uid <- map["uid"]
            test <- map["test"]
            key <- map["key"]
            status <- map["status"]
            description <- map["desc"]
        }
    }

    ///
    public class MeasurementQosResultDetailTestDescription: Mappable {

        ///
        public var name: String?

        ///
        public var type: QOSMeasurementType?

        ///
        public var description: String?

        ///
        public init() {

        }

        ///
        required public init?(_ map: Map) {

        }

        ///
        public func mapping(map: Map) {
            name <- map["name"]
            type <- map["test_type"]
            description <- map["desc"]
        }
    }
}
