//
//  ResponseObjects.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 31.05.16.
//
//

import Foundation
import ObjectMapper

///
public class BasicResponse: Mappable, CustomStringConvertible {

    ///
    public var description: String {
        return "<empty BasicResponse>"
    }

    ///
    public init() {

    }

    ///
    required public init?(_ map: Map) {

    }

    ///
    public func mapping(map: Map) {

    }
}

///
public class IpResponse: BasicResponse {

    ///
    var ip: String = ""

    ///
    var version: String = ""

    ///
    override public func mapping(map: Map) {
        ip <- map["ip"]
        version <- map["version"]
    }

    override public var description: String {
        return "ip: \(ip), version: \(version)"
    }
}

////////////////////////////////////////////

class SettingsResponseClient: Mappable, CustomStringConvertible {

    var clientType = ""
    var termsAndConditionsAccepted = false
    var termsAndConditionsAcceptedVersion = 0
    var uuid: String?

    init() {

    }

    required init?(_ map: Map) {

    }

    func mapping(map: Map) {
        clientType <- map["clientType"]
        termsAndConditionsAccepted <- map["termsAndConditionsAccepted"]
        termsAndConditionsAcceptedVersion <- map["termsAndConditionsAcceptedVersion"]
        uuid <- map["uuid"]
    }

    var description: String {
        return "clientType: \(clientType), uuid: \(uuid)"
    }
}

class SettingsReponse: BasicResponse {

    var client: SettingsResponseClient?

    override func mapping(map: Map) {
        super.mapping(map)

        client <- map["client"]
    }

}

///
public class SpeedMeasurementResponse: BasicResponse {

    ///
    public var testToken: String?

    ///
    public var testUuid: String?

    ///
    public var clientRemoteIp: String?

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
    public var measurementServer: TargetMeasurementServer?

    ///
    override public func mapping(map: Map) {
        super.mapping(map)

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
    override public var description: String {
        return "SpeedMeasurmentResponse: testToken: \(testToken), testUuid: \(testUuid), clientRemoteIp: \n\(clientRemoteIp)"
    }

    ///
    public class TargetMeasurementServer: Mappable {

        ///
        var address: String?

        ///
        var encrypted = false

        ///
        public var name: String?

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
        required public init?(_ map: Map) {

        }

        ///
        public func mapping(map: Map) {
            address     <- map["address"]
            encrypted   <- map["is_encrypted"]
            name        <- map["name"]
            port        <- map["port"]
            uuid        <- map["uuid"]
            ip          <- map["ip"]
        }
    }
}

///
class SpeedMeasurementSubmitResponse: BasicResponse {

    ///
    var openTestUuid: String?

    ///
    var testUuid: String?

    ///
    override func mapping(map: Map) {
        super.mapping(map)

        openTestUuid <- map["open_test_uuid"]
        testUuid <- map["test_uuid"]
    }
}

///
public class SpeedMeasurementResultResponse: BasicResponse {

    ///
    public var classifiedMeasurementDataList: [ClassifiedResultItem]?

    ///
    public var networkDetailList: [ResultItem]?

    ///
    public var networkType: Int?

    ///
    public var openTestUuid: String?

    ///
    public var openUuid: String?

    ///
    public var time: Int?

    ///
    public var timeString: String?

    ///
    public var timezone: String?

    ///
    public var location: String?

    ///
    public var latitude: Double?

    ///
    public var longitude: Double?

    ///
    public var shareText: String?

    ///
    public var shareSubject: String?

    ///
    override public func mapping(map: Map) {
        super.mapping(map)

        classifiedMeasurementDataList <- map["measurement"]
        networkDetailList <- map["net"]

        networkType <- map["network_type"]

        openTestUuid <- map["open_test_uuid"]
        openUuid <- map["open_uuid"]
        time <- map["time"]
        timeString <- map["time_string"]
        timezone <- map["timezone"]
        location <- map["location"]
        latitude <- map["geo_lat"]
        longitude <- map["geo_long"]
        shareText <- map["share_text"]
        shareSubject <- map["share_subject"]
    }

    ///
    public class ResultItem: Mappable {

        ///
        public var value: String?

        ///
        public var title: String?

        ///
        init() {

        }

        ///
        required public init?(_ map: Map) {

        }

        ///
        public func mapping(map: Map) {
            value <- map["value"]
            title <- map["title"]
        }
    }

    ///
    public class ClassifiedResultItem: ResultItem {

        ///
        public var classification: Int?

        ///
        override public func mapping(map: Map) {
            super.mapping(map)

            classification <- map["classification"]
        }
    }
}

///
public class SpeedMeasurementDetailResultResponse: BasicResponse {

    ///
    public var speedMeasurementResultDetailList: [SpeedMeasurementDetailItem]?

    ///
    override public func mapping(map: Map) {
        super.mapping(map)

        speedMeasurementResultDetailList <- map["testresultdetail"]
    }

    ///
    public class SpeedMeasurementDetailItem: Mappable {

        ///
        public var key: String?

        ///
        public var value: String?

        ///
        public var title: String?

        ///
        public init() {

        }

        ///
        required public init?(_ map: Map) {

        }

        ///
        public func mapping(map: Map) {
            key <- map["key"]
            value <- map["value"]
            title <- map["title"]
        }
    }
}

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
        super.mapping(map)

        testToken <- map["test_token"]
        testUuid <- map["test_uuid"]

        objectives <- map["objectives"]
    }

    ///
    override var description: String {
        return "QosMeasurmentResponse: testToken: \(testToken), testUuid: \(testUuid), objectives: \n\(objectives)"
    }
}

///
class QosMeasurementSubmitResponse: BasicResponse {

    ///
    override func mapping(map: Map) {
        super.mapping(map)
    }
}

///
public class QosMeasurementResultResponse: BasicResponse {

    ///
    public var evaluation: String?

    ///
    public var evalTimes: [String: AnyObject]?

    ///
    public var testResultDetail: [MeasurementQosResult]?

    ///
    public var testResultDetailDescription: [String: AnyObject]?

    ///
    public var testResultDetailTestDescription: [String: AnyObject]?

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
        public var result: AnyObject?

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
}

///
public class HistoryItem: BasicResponse {

    ///
    public var testUuid: String?

    ///
    public var time: Int?

    ///
    public var timeZone: String?

    ///
    public var timeString: String?

    ///
    public var speedDownload: String?

    ///
    public var speedUpload: String?

    ///
    public var ping: String?

    ///
    public var pingShortest: String?

    ///
    public var model: String?

    ///
    public var networkType: String?

    ///
    public var speedDownloadClassification: Int?

    ///
    public var speedUploadClassification: Int?

    ///
    public var pingClassification: Int?

    ///
    public var pingShortClassification: Int?

    ///
    override public func mapping(map: Map) {
        super.mapping(map)

        testUuid        <- map["test_uuid"]
        time            <- map["time"]
        timeZone        <- map["time_zone"]
        timeString      <- map["time_string"]
        speedDownload   <- map["speed_download"]
        speedUpload     <- map["speed_upload"]
        ping            <- map["ping"]
        pingShortest    <- map["ping_shortest"]
        model           <- map["model"]
        networkType     <- map["network_type"]
        speedDownloadClassification <- map["speed_download_classification"]
        speedUploadClassification   <- map["speed_upload_classification"]
        pingClassification          <- map["ping_classification"]
        pingShortClassification     <- map["ping_short_classification"]
    }
}
