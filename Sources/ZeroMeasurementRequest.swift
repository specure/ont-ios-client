//
//  ZeroMeasurementRequest.swift
//  RMBTClient
//
//  Created by Sergey Glushchenko on 10/4/17.
//

import UIKit
import ObjectMapper

class ZeroMeasurementRequest: BasicRequest {
    
    ///
    var clientUuid: String?
    ///
    var geoLocations = [GeoLocation]()
    var cellLocations = [FakeCellLocation]()
    ///
    var networkType: Int?
    ///
    var time: Date?
    
    #if os(iOS)
    
    ///
    var signals = [Signal]()
    
    ///
    var telephonyInfo: TelephonyInfo?
    
    ///
    var wifiInfo: WifiInfo?
    
    #endif
    
    init(measurement: StoredZeroMeasurement) {
        super.init()
        if let speedMeasurement = measurement.speedMeasurementResult() {
            self.clientUuid = speedMeasurement.clientUuid
            self.geoLocations = speedMeasurement.geoLocations
            self.networkType = speedMeasurement.networkType
            self.time = speedMeasurement.time
            #if os(iOS)
            self.signals = speedMeasurement.signals
            for signal in self.signals {
                if signal.time == nil {
                    signal.time = Int(Date().timeIntervalSince1970)
                }
            }
            self.telephonyInfo = speedMeasurement.telephonyInfo
            self.wifiInfo = speedMeasurement.wifiInfo
            #endif
            self.uuid = speedMeasurement.uuid
            self.apiLevel = speedMeasurement.apiLevel
            self.clientName = speedMeasurement.clientName
            self.device = speedMeasurement.device
            self.model = speedMeasurement.model
            self.osVersion = speedMeasurement.osVersion
            self.platform = speedMeasurement.platform
            self.plattform = speedMeasurement.plattform
            self.product = speedMeasurement.product
            self.previousTestStatus = speedMeasurement.previousTestStatus
            self.softwareRevision = speedMeasurement.softwareRevision
            self.softwareVersion = speedMeasurement.softwareVersion
            self.clientVersion = speedMeasurement.clientVersion
            self.softwareVersionCode = speedMeasurement.softwareVersionCode
            self.softwareVersionName = speedMeasurement.softwareVersionName
            self.timezone = speedMeasurement.timezone
            self.clientType = speedMeasurement.clientType
            
            self.cellLocations = [FakeCellLocation()]
        }
        
    }
    
    required public init?(map: Map) {
        fatalError("init(map:) has not been implemented")
    }
    
    ///
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        clientUuid              <- map["client_uuid"]
        geoLocations            <- map["geoLocations"]
        networkType             <- map["network_type"]
        time                    <- map["time"]
        
        #if os(iOS)
            signals             <- map["signals"]
            telephonyInfo       <- map["telephony_info"]
            wifiInfo            <- map["wifi_info"]
            cellLocations       <- map["cellLocations"]
        #endif
    }
    
    class func submit(zeroMeasurements: [ZeroMeasurementRequest], success: @escaping (_ response: SpeedMeasurementSubmitResponse) -> (), error failure: @escaping ErrorCallback) {
        let controlServer = ControlServer.sharedControlServer
        
        controlServer.submitZeroMeasurementRequests(zeroMeasurements, success: success, error: failure)
    }
}

