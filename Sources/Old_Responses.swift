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

open class MeasurementServerInfoResponse: BasicResponse {
    
    ///
    open var servers: [Servers]?
    
    
    ///
    override open func mapping(map: Map) {
        super.mapping(map: map)
        
//        servers <- map["servers"]
    }
    
    ///
    open class Servers: Mappable {
        
        ///
        open var address: String?
        
        ///
        open var port: String?
        
        ///
        open var name: String?
        
        ///
        open var id: NSNumber?

        open var country: String?
        open var distance: String?
        open var city: String?
        open var sponsor: String?
        open var company: String?
        
        open var fullNameWithDistance: String? {
            let name = fullName
            if let distance = distance {
                return "\(name) (\(distance))"
            } else {
                return name
            }
        }
        
        open var fullName: String {
            var parts: [String] = []
            
            if let city = self.city {
                parts.append(city)
            }
            
            if let country = self.country {
                parts.append(country)
            }
            
            let name = parts.joined(separator: ", ")
            return name
        }
        
        open var fullNameWithSponsor: String {
            var parts: [String] = []
            if let sponsor = self.sponsor {
                parts.append(sponsor)
            } else if let company = self.company {
                parts.append(company)
            }
            
            if let city = self.city {
                parts.append(city)
            }
            
            if let country = self.country {
                parts.append(country)
            }
            
            let name = parts.joined(separator: ", ")
            return name
        }
        
        open var fullNameWithDistanceAndSponsor: String? {
            let name = fullNameWithSponsor
            if let distance = distance {
                return "\(name) (\(distance))"
            } else {
                return name
            }
        }
        ///
        public init(id: NSNumber?) {
            self.id = id
        }
        
        ///
        required public init?(map: Map) {
            self.mapping(map: map)
        }
        
        ///
        public func mapping(map: Map) {
            address     <- map["address"]
            port        <- map["port"]
            name        <- map["name"]
            id          <- map["id"]
            country     <- map["country"]
            distance    <- map["distance"]
            city        <- map["city"]
            sponsor     <- map["sponsor"]
            company     <- map["company"]
        }
    }
}

///
final public class HistoryWithFiltersResponse: BasicResponse {
    public var records: [HistoryItem] = []

    override public func mapping(map: Map) {
        super.mapping(map: map)
        
        records <- map["history.content"]
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
open class BasicMeasurementResponse: BasicResponse {
    
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
    
    open var testServerType: String?
    
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
        testServerType      <- map["test_server_type"]
        

        
        resultURLString <- map["result_url"]
        waitDuration <- map["test_wait"]
        
    }
}

extension SpeedMeasurementResponse_Old {
    func toSpeedMeasurementResponse() -> SpeedMeasurementResponse {
        let r = SpeedMeasurementResponse()
        r.clientRemoteIp = self.clientRemoteIp
        r.duration = self.duration
        r.pretestDuration = self.pretestDuration
        r.numPings = Int(self.numPings)!
        r.numThreads = Int(self.numThreads)!
        r.testToken = self.testToken
        r.testUuid = self.testUuid
        r.testServerType = self.testServerType
        
        let measure = TargetMeasurementServer()
        measure.port = self.port?.intValue
        measure.address = self.serverAddress
        measure.name = self.serverName
        measure.encrypted = self.serverEncryption
        measure.uuid = self.testUuid
        
        r.add(details:measure)
        
        return r
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
    open class Settings: Mappable {
        
        ///
        var urls: UrlSettings?
        
        ///
        var versions: VersionSettings?
        
        ///
        var advertised_speed_option: [String]?
        
        //
        var qosMeasurementTypes:[QOSTestTypes]?
        
        ///
        var map_server: MapServerSettings?
        
        ///
        var uuid: String?
        
        ///
        var history: HistoryFilterType?
        
        var surveySettings: SurveySettings?
        
        ///
        init() {
            
        }
        
        ///
        required public init?(map: Map) {
            
        }
        
        ///
        public func mapping(map: Map) {
            advertised_speed_option <- map["advertised_speed_option"]
            qosMeasurementTypes <- map["qostesttype_desc"]
            urls <- map["urls"]
            versions <- map["versions"]
            
            map_server <- map["map_server"]
            uuid <- map["uuid"]
            history <- map["history"]
            surveySettings <- map["survey_settings"]
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
        
        open class SurveySettings: Mappable {
            
            ///
            var surveyUrl: String?
            var isActiveService: Bool?
            var dateStarted: Double?
            
            ///
            init() {
                
            }
            
            ///
            required public init?(map: Map) {
                
            }
            
            ///
            public func mapping(map: Map) {
                surveyUrl <- map["survey_url"]
                isActiveService <- map["is_active_service"]
                dateStarted <- map["date_started"]
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
            var description: String {
                return "Test Type: \(String(describing: testType)), with Description: \(String(describing: testDesc))"
            }
        }
    }
}

