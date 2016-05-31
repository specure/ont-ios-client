//
//  RequestObjects.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 31.05.16.
//
//

import Foundation
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

///
class SettingsRequest: BasicRequest {
    
    ///
    var client: SettingsResponseClient?
    
    ///
    override func mapping(map: Map) {
        super.mapping(map)
        
        client <- map["client"]
    }
    
}

///
class SpeedMeasurementRequest: BasicRequest {
    
    var uuid: String?
    
    var ndt: Bool? = false
    
    var time: UInt64?
    
    var version: String?
    
    var testCounter: UInt?
    
    ///
    override func mapping(map: Map) {
        super.mapping(map)
        
        uuid <- map["uuid"]
        ndt <- map["ndt"]
        time <- map["time"]
        version <- map["version"]
        testCounter <- map["test_counter"]
    }
}

///
class QosMeasurementRequest: BasicRequest {
    
    var clientUuid: String?
    
    var measurementUuid: String?
    
    ///
    override func mapping(map: Map) {
        super.mapping(map)
        
        clientUuid <- map["clientUuid"]
        measurementUuid <- map["measurementUuid"]
    }
}


