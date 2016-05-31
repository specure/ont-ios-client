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
public class IpResponse: Mappable, CustomStringConvertible {
    
    ///
    var ip: String = ""
    
    ///
    var version: String = ""
    
    ///
    required public init?(_ map: Map) {
        
    }
    
    ///
    public func mapping(map: Map) {
        ip <- map["ip"]
        version <- map["version"]
    }
    
    public var description: String {
        return "ip: \(ip), version: \(version)"
    }
}

////////////////////////////////////////////

public class SettingsResponseClient: Mappable, CustomStringConvertible {
    
    var clientType = ""
    var termsAndConditionsAccepted = false
    var termsAndConditionsAcceptedVersion = 0
    var uuid = ""
    
    init() {
        
    }
    
    required public init?(_ map: Map) {
        
    }
    
    public func mapping(map: Map) {
        clientType <- map["clientType"]
        termsAndConditionsAccepted <- map["termsAndConditionsAccepted"]
        termsAndConditionsAcceptedVersion <- map["termsAndConditionsAcceptedVersion"]
        uuid <- map["uuid"]
    }
    
    public var description: String {
        return "clientType: \(clientType), uuid: \(uuid)"
    }
}

public class SettingsReponse: Mappable {
    
    var client: SettingsResponseClient?
    
    init() {
        
    }
    
    required public init?(_ map: Map) {
        
    }
    
    public func mapping(map: Map) {
        client <- map["client"]
    }
    
}