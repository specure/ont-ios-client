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
open class IpResponse_Old: BasicResponse {
    
    ///
    var ip: String = ""
    
    ///
    var version: String = ""
    
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
class SettingsReponse_Old: BasicResponse {
    
    ///
    var settings: [Settings]?
    
    ///
    var error: [String]?
    
    
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        settings <- map["settings"]
        error <- map["error"]
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

