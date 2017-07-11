//
//  Old_Request.swift
//  rmbt-ios-client
//
//  Created by Tomas Baculák on 10/07/2017.
//
//

import Foundation
import ObjectMapper

///
///
open class HistoryWithFiltersRequest: BasicRequest {
    
    var uuid:String?
    var resultOffset:NSNumber?
    var resultLimit:NSNumber?
    
    ///
    override public func mapping(map: Map) {
        super.mapping(map: map)
        
        uuid <- map["uuid"]
        
        resultOffset <- map["result_offset"]
        resultLimit <- map["result_limit"]
    }
    
}


///
open class GetSyncCodeRequest: BasicRequest {
    
    var uuid:String?
    
    ///
    override public func mapping(map: Map) {
        super.mapping(map: map)
        
        uuid <- map["uuid"]
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
    var uuid: String?
    
    ///
    override public func mapping(map: Map) {
        super.mapping(map: map)
        
        uuid <- map["uuid"]
    }
}
///
///
open class ServerSettingsRequest_Old: BasicRequest {
    
    ///
    var time:UInt64?
    ///
    var uuid: String?
    ///
    var name: String = "RMBT"
    ///
    var client: String = "RMBT"
    ///
    var type: String = "MOBILE"
    
    ///
    override public func mapping(map: Map) {
        super.mapping(map: map)
        
        time <- map["time"]
        uuid <- map["uuid"]
        type <- map["type"]
        client <- map["client"]
        name <- map["name"]
    }
}

///
open class SettingsRequest_Old: BasicRequest {
    
    ///
    var termsAndConditionsAccepted = false
    
    ///
    var termsAndConditionsAccepted_Version = 0
    
    ///
    var uuid: String?
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
        uuid <- map["uuid"]
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



