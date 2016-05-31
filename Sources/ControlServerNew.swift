//
//  ControlServerNew.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 31.05.16.
//
//

import Foundation
import Alamofire
import AlamofireObjectMapper
import ObjectMapper

///
class BasicRequest: Mappable {

    var apiLevel: String?
    
    var clientName: String?
    
    var device: String?
    
    var language: String?
    
    var model: String?

    var osVersion: String?
    
    var platform: String?
    
    var product: String?
    
    var previousTestStatus: String?
    
    var softwareRevision: String?
    
    var softwareVersion: String?
    
    var softwareVersionCode: Int?
    
    var softwareVersionName: String?
    
    var timezone: String?
    
    var clientType: String? // ClientType enum
    
    ///
    init() {
    
    }
    
    ///
    required init?(_ map: Map) {
        
    }
    
    ///
    func mapping(map: Map) {
        apiLevel            <- map["api_level"]
        clientName          <- map["client_name"]
        device              <- map["device"]
        language            <- map["language"]
        model               <- map["model"]
        osVersion           <- map["os_version"]
        platform            <- map["platform"]
        product             <- map["product"]
        previousTestStatus  <- map["previous_test_status"]
        softwareRevision    <- map["software_revision"]
        softwareVersion     <- map["software_version"]
        softwareVersionCode <- map["software_version_code"]
        softwareVersionName <- map["software_version_name"]
        timezone            <- map["timezone"]
        clientType          <- map["client_type"]
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////////

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

public class SettingsRequest: Mappable {
    
    var client: SettingsResponseClient?
    
    init() {
        
    }
    
    required public init?(_ map: Map) {
        
    }
    
    public func mapping(map: Map) {
        client <- map["client"]
    }

}


///
public typealias IpResponseSuccessCallback = (ipResponse: IpResponse) -> ()

///
public typealias NEWErrorCallback = (error: NSError) -> ()

///
public class ControlServerNew {
    
    ///
    public static let sharedControlServer = ControlServerNew()
    
    ///
    private init() {
    
    }

    ///
    public func getIpv4(successCallback: IpResponseSuccessCallback, errorCallback: NEWErrorCallback) {
        self.getIpVersion("http://localhost:8080/api/v1/ip", successCallback: successCallback, errorCallback: errorCallback) // TODO: ipv4 url
    }

    ///
    public func getIpv6(successCallback: IpResponseSuccessCallback, errorCallback: NEWErrorCallback) {
        self.getIpVersion("http://localhost:8080/api/v1/ip", successCallback: successCallback, errorCallback: errorCallback) // TODO: ipv6 url
    }
    
    ///
    public func getIpVersion(url: String, successCallback: IpResponseSuccessCallback, errorCallback: NEWErrorCallback) {
    
        self.request(.POST, path: "/ip", requestObject: BasicRequest()) { (response: Response<IpResponse, NSError>) in
            // TODO: check error
            
            if let ipResponse = response.result.value {
                successCallback(ipResponse: ipResponse)
            }
            
            /*if let error = response.error {
             errorCallback(error)
             }*/
        }
    }

    
    public func getSettings(success: EmptyCallback, error failure: NEWErrorCallback) {
        
        let settingsRequest = SettingsRequest()
        settingsRequest.client = SettingsResponseClient()
        settingsRequest.client?.clientType = "MOBILE"
        settingsRequest.client?.termsAndConditionsAccepted = true
        
        let JSON = Mapper().toJSON(settingsRequest)
        
        Alamofire.request(.POST, "http://localhost:8080/api/v1/settings", parameters: JSON, encoding: .JSON).responseObject { (response: Response<SettingsReponse, NSError>) in
            
            if let settingsResponse = response.result.value {
                print(settingsResponse.client)
                success()
            }
        }
    }
    
    ///
    private func request<T: Mappable>(method: Alamofire.Method, path: String, requestObject: BasicRequest, callback: (response: Response<T, NSError>) -> ()) {
        // add basic request values (TODO: make device independent -> for osx, tvos)
        let infoDictionary = NSBundle.mainBundle().infoDictionary! // !
        let currentDevice = UIDevice.currentDevice()

        requestObject.apiLevel = nil // always null on iOS...
        requestObject.clientName = "RMBT"
        requestObject.device = currentDevice.model
        requestObject.language = RMBTPreferredLanguage()
        requestObject.model = UIDeviceHardware.platform()
        requestObject.osVersion = currentDevice.systemVersion
        requestObject.platform = "iOS"
        requestObject.product = nil // always null on iOS...
        requestObject.previousTestStatus = "TODO" // TODO: from settings
        requestObject.softwareRevision = RMBTBuildInfoString()
        requestObject.softwareVersion = infoDictionary["CFBundleShortVersionString"] as? String
        requestObject.softwareVersionCode = infoDictionary["CFBundleVersion"] as? Int
        requestObject.softwareVersionName = "0.3" // ??
        requestObject.timezone = NSTimeZone.systemTimeZone().name
        requestObject.clientType = "MOBILE"
        
        let parameters = Mapper().toJSON(requestObject)
        
        logger.debug {
            if let jsonString = Mapper().toJSONString(requestObject, prettyPrint: true) {
                return "Requesting \(path) with object: \n\(jsonString)"
            }
            
            return "Requesting \(path) with object: <json serialization failed>"
        }
        
        Alamofire.request(method, "http://localhost:8080/api/v1\(path)", parameters: parameters, encoding: .JSON).responseObject { (response: Response<T, NSError>) in
            // TODO: check error
            
            if let responseObj: T = response.result.value {
                
                logger.debug {
                    if let jsonString = Mapper().toJSONString(responseObj, prettyPrint: true) {
                        return "Response for \(path) with object: \n\(jsonString)"
                    }
                    
                    return "Response for \(path) with object: <json serialization failed>"
                }
                
                callback(response: response)
            }
        }
    }
    
}
