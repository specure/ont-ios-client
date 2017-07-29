//
//  Old_Responses.swift
//  rmbt-ios-client
//
//  Created by Tomas Baculák on 10/07/2017.
//
//

import Foundation
import ObjectMapper
//

///
open class ResultItem: BasicResponse {
    
    ///
    open var value: String?
    ///
    open var title: String?
    
    ///
    open override func mapping(map: Map) {
        value <- map["value"]
        title <- map["title"]
    }
}

open class HistoryWithFiltersResponse: BasicResponse {

    ///
    open var records: [[String:Any?]] = []

    
    ///
    override open func mapping(map: Map) {
        super.mapping(map: map)
        
        records <- map["history"]
    }
}

///
open class MapMeasurementResponse_Old: BasicResponse {
    
    ///
    open var measurements: [SpeedMeasurementResultResponse]?
    
    ///
    override open func mapping(map: Map) {
        super.mapping(map: map)
        
        measurements <- map["testresult"]
    }
}

///
open class IpResponse_Old: BasicResponse {
    
    ///
    open var ip: String = ""
    
    ///
    open var version: String = ""
    
    
    ///
    override open func mapping(map: Map) {
        super.mapping(map: map)
        
        ip <- map["ip"]
        version <- map["v"]
    }
    
    override open var description: String {
        return "ip: \(ip), version: \(version)"
    }
}

///
open class GetSyncCodeResponse: BasicResponse {

    //
    open var codes:[Result]?
    
    ///
    override open func mapping(map: Map) {
        super.mapping(map: map)
        
        codes <- map["sync"]
    }
    
    open class Result: Mappable {
        
        //
        open var code:String?
        
        ///
        init() {
            
        }
        
        ///
        required public init?(map: Map) {
            
        }
        
        ///
        public func mapping(map: Map) {
            code <- map["sync_code"]
        }
        
    }
}
///
open class SyncCodeResponse: BasicResponse {
    
    //
    var codes:Result?
    
    ///
    override open func mapping(map: Map) {
        super.mapping(map: map)
        
        codes <- map["sync"]
    }
    
    class Result: Mappable {
        
        //
        var results:[[String:Any?]] = []
        
        //
        var isSynchronize:Bool = false
        
        
        ///
        init() {
            
        }
        
        ///
        required init?(map: Map) {
            
        }
        
        ///
        func mapping(map: Map) {
            results <- map["success"]
        }
        
    }
}

open class SpeedMeasurementResponse_Old: BasicResponse {
    
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
    var numThreads = "3"
    
    ///
    var numPings = "10"
    
    ///
    var testWait: Double = 0 // TODO: int instead of double?
    
    ///
    open var port:NSNumber?
    
    ///
    open var serverAddress:String?
    
    ///
    open var serverEncryption:Bool = false
    
    ///
    open var serverName:String?
    
    ///
    open var resultURLString:String?
    
    ///
    open var waitDuration:Int?
    
    ///
    override open func mapping(map: Map) {
        super.mapping(map: map)
        
        testToken           <- map["test_token"]
        testUuid            <- map["test_uuid"]
        
        clientRemoteIp      <- map["client_remote_ip"]
        duration            <- map["test_duration"]

        numThreads          <- map["test_numthreads"]
        numPings            <- map["test_numpings"]
        testWait            <- map["test_wait"]
        port                <- map["test_server_port"]
        
        serverAddress       <- map["test_server_address"]
        serverEncryption    <- map["test_server_encryption"]
        serverName          <- map["test_server_name"]

        
        resultURLString <- map["result_url"]
        waitDuration <- map["test_wait"]
        
    }
}

///
open class SettingsReponse_Old: BasicResponse {
    
    ///
    var settings: [Settings]?
    
    
    override open func mapping(map: Map) {
        super.mapping(map: map)
        
        settings <- map["settings"]
    }
    
    
    ///
    class Settings: Mappable {
        
        ///
        var urls: UrlSettings?
        
        ///
        var versions: VersionSettings?
        
        ///
        var advertised_speed_option: [String]?
        
        //
        var qosMeasurementTypes:[QOSTestTypes]?
        
        ///
        var map_server: String?
        
        ///
        var uuid: String?
        
        ///
        var history: [String: [String]]?
        
        ///
        init() {
            
        }
        
        ///
        required init?(map: Map) {
            
        }
        
        ///
        func mapping(map: Map) {
            advertised_speed_option <- map["advertised_speed_option"]
            qosMeasurementTypes <- map["qostesttype_desc"]
            urls <- map["urls"]
            versions <- map["versions"]
            
            map_server <- map["map_server"]
            uuid <- map["uuid"]
            history <- map["history"]
        }
        
        ///
        class UrlSettings: Mappable {
            
            ///
            var ipv4IpCheck: String?
            
            ///
            var ipv6IpCheck: String?
            
            ///
            var ipv4IpOnly: String?
            
            ///
            var ipv6IpOnly: String?
            
            ///
            var statistics: String?
            
            ///
            var opendataPrefix: String?
            
            ///
            init() {
                
            }
            
            ///
            required init?(map: Map) {
                
            }
            
            ///
            func mapping(map: Map) {
                ipv4IpOnly     <- map["control_ipv4_only"]
                ipv6IpOnly     <- map["control_ipv6_only"]
                ipv4IpCheck     <- map["url_ipv4_check"]
                ipv6IpCheck     <- map["url_ipv6_check"]
                statistics      <- map["statistics"]
                opendataPrefix  <- map["open_data_prefix"]
            }
        }
        
        ///
        class VersionSettings: Mappable {
            
            ///
            var controlServerVersion: String?
            
            ///
            init() {
                
            }
            
            ///
            required init?(map: Map) {
                
            }
            
            ///
            func mapping(map: Map) {
                controlServerVersion <- map["control_server_version"]
            }
        }
        
        class QOSTestTypes:Mappable {
            
            
            ///
            var testDesc: String?
            
            ///
            var testType: String?
            
            
            ///
            init() {
                
            }
            
            ///
            required init?(map: Map) {
                
            }
            
            ///
            func mapping(map: Map) {
                testDesc <- map["name"]
                testType <- map["test_type"]
            }
            
            //            ///
            //            var description: String {
            //                return "Test Type: \(testType), with Description: \(testDesc)"
            //            }
        }
    }
}

