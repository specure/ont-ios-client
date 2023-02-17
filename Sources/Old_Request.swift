//
//  Old_Request.swift
//  rmbt-ios-client
//
//  Created by Tomas Baculák on 10/07/2017.
//
//

import Foundation
import ObjectMapper
import CoreLocation

///
open class MeasurementServerInfoRequest: BasicRequest {
    
    var client: String = "RMBT"
    var geoLocation: GeoLocation?
    
    override public func mapping(map: Map) {
        super.mapping(map: map)
        
        client <- map["client"]
        geoLocation <- map["location"]
    }
}

///
open class HistoryWithQOSRequest: BasicRequest {

    var testUUID: String?
    var capabilities: [String: Any] = [
        "classification": [ "count": 4 ],
        "qos": [ "supports_info": true ],
        "RMBThttp": true
    ]
    
    override public func mapping(map: Map) {
        super.mapping(map: map)
        
        capabilities <- map["capabilities"]
        testUUID <- map["test_uuid"]
    }
}
///
final class HistoryWithFiltersRequest: BasicRequest {
    var networks:[String]?
    var devices: [String]?

    override public func mapping(map: Map) {
        super.mapping(map: map)
        networks <- map["network_types"]
        devices <- map["devices"]
    }
}


///
open class GetSyncCodeRequest: BasicRequest {
    
    ///
    override public func mapping(map: Map) {
        super.mapping(map: map)
    }

}

///
open class SyncCodeRequest: BasicRequest {

    var code:String!
    
    ///
    override public func mapping(map: Map) {
        super.mapping(map: map)
        
        code <- map["sync_code"]
    }
}

///
open class IPRequest_Old: BasicRequest {
    
    ///
    var software_Version_Code: String = "6666" // and more than that
//    var plattform:String = ""
    
    ///
    override public func mapping(map: Map) {
        super.mapping(map: map)
        
        software_Version_Code <- map["softwareVersionCode"]
        // there is a bug on the server side that's why double t !!!
        plattform <- map["plattform"]
        
    }
}
///
///
public class SpeedMeasurementRequest_Old: BasicRequest {    
    ///
    var ndt = false
    
    ///
    var anonymous = false
    
    ///
    var time: UInt64?
    
    ///
    var version: String = "0.3"
    
    ///
    var testCounter: UInt?
    
    ///
    var geoLocation: GeoLocation?
    
    ///
    var name = "RMBT"
    
    ///
    var type = "MOBILE"
    
    ///
    var client = "RMBT"
    
    var measurementTypeFlag = "dedicated"
    
    ///
    var measurementServerId: UInt64?
    
    var telephonyPermissionGranted = false
    var locationPermissionGranted = false
    var uuidPermissionGranted = false
    
    var userLoopMode: Bool?
    var loopModeInfo: [String:Any]? {
        didSet {
            if let _ = loopModeInfo {
                userLoopMode = true
            } else {
                userLoopMode = false
            }
        }
    }
    
    ///
    public override func mapping(map: Map) {
        super.mapping(map: map)
        
        
        ndt         <- map["ndt"]
        anonymous   <- map["anonymous"]
        version     <- map["version"]
        testCounter <- map["testCounter"]
        
        geoLocation <- map["location"]
        
        time <- map["time"]
        name <- map["name"]
        type <- map["type"]
        client <- map["client"]
        
        //
        measurementServerId <- map["prefer_server"]
        measurementTypeFlag <- map["measurement_type_flag"]
        
        telephonyPermissionGranted <- map["telephony_permission_granted"]
        locationPermissionGranted <- map["location_permission_granted"]
        uuidPermissionGranted <- map["uuid_permission_granted"]
        
        userLoopMode        <- map["user_loop_mode"]
        loopModeInfo        <- map["loopmode_info"]
    }
}

///
open class SettingsRequest_Old: BasicRequest {
    
    ///
    var termsAndConditionsAccepted = false
    
    ///
    var termsAndConditionsAccepted_Version = 0
    
    ///
    var name: String = "RMBT"
    ///
    var client: String = "RMBT"
    ///
    var type: String = "MOBILE"
    
    ///
    override public func mapping(map: Map) {
        super.mapping(map: map)
        
        termsAndConditionsAccepted <- map["terms_and_conditions_accepted"]
        termsAndConditionsAccepted_Version <- map["terms_and_conditions_accepted_version"]

        type <- map["type"]
        client <- map["client"]
        name <- map["name"]
    }
}

///
open class CheckSurveyRequest: BasicRequest {
    
    ///
    var clientUuid: String = ""

    ///
    override public func mapping(map: Map) {
        clientUuid <- map["client_uuid"]
    }
}
