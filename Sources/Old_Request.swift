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
    
    var client:String = "RMBT"
    
    override public func mapping(map: Map) {
        super.mapping(map: map)
        
        
        client <- map["client"]
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
    
    var resultOffset:NSNumber?
    var resultLimit:NSNumber?
    
    ///
    override public func mapping(map: Map) {
        super.mapping(map: map)
        
        
        resultOffset <- map["result_offset"]
        resultLimit <- map["result_limit"]
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
    var software_Version_Code: String = "666"
    var plattform:String = ""
    
    ///
    override public func mapping(map: Map) {
        super.mapping(map: map)
        
        software_Version_Code <- map["softwareVersionCode"]
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
class BasicRequest_Old: Mappable {
    
    ///
    var apiLevel: String = ""
    
    ///
    var clientName: String?
    
    ///
    var device: String?
    
    ///
    var language: String?
    
    ///
    var model: String?
    
    ///
    var osVersion: String?
    
    ///
    var platform: String?
    
    ///
    var product: String = ""
    
    ///
    var previousTestStatus: String?
    
    ///
    var softwareRevision: String?
    
    ///
    var softwareVersion: String?
    
    ///
    var clientVersion: String? // TODO: fix this on server side
    
    ///
    var softwareVersionCode: Int?
    
    ///
    var softwareVersionName: String?
    
    ///
    var timezone: String?
    
    ///
    var clientType: String? // ClientType enum
    
    ///
    init() {
        
    }
    
    ///
    required init?(map: Map) {
        
    }
    
    ///
    func mapping(map: Map) {
        apiLevel            <- map["api_level"]
        clientName          <- map["name"]
        device              <- map["device"]
        
        language            <- map["language"]
        
        model               <- map["model"]
        osVersion           <- map["version"]
        platform            <- map["platform"]
        product             <- map["product"]
        softwareRevision    <- map["softwareRevision"]
        
        softwareVersion     <- map["softwareVersion"]
        softwareVersionCode <- map["softwareVersionCode"]
        
        clientVersion       <- map["client"] // TODO: fix this on server side
        
        
        timezone            <- map["timezone"]
        clientType          <- map["type"]
    }
}


