//
//  SpeedMeasurementResponse.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 23.08.16.
//
//

import Foundation
import ObjectMapper

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
