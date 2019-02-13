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
open class HistoryWithQOS: BasicRequest {

    var testUUID:String?
    
    override public func mapping(map: Map) {
        super.mapping(map: map)
        
        
        testUUID <- map["test_uuid"]
    }
}
///
open class HistoryWithFiltersRequest: BasicRequest {
    //
    var resultOffset:NSNumber?
    //
    var resultLimit:NSNumber?
    //
    var networks:[String]?
    //
    var devices: [String]?
    
    ///
    override public func mapping(map: Map) {
        super.mapping(map: map)
        
        resultOffset <- map["result_offset"]
        resultLimit <- map["result_limit"]
        networks <- map["networks"]
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
class SpeedMeasurementRequest_Old: BasicRequest {
    
    
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
    
    ///
    var measurementServerId: UInt64?
    
    
    ///
    override func mapping(map: Map) {
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
        measurementServerId <- map["measurement_server_id"]

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
