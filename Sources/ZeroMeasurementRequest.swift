//
//  ZeroMeasurementRequest.swift
//  RMBTClient
//
//  Created by Sergey Glushchenko on 10/4/17.
//

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
    
    /// Telephony Info properties
    var telephonyInfo: TelephonyInfo? {
        didSet {
            self.telephonyDataState = telephonyInfo?.dataState
            self.telephonyNetworkCountry = telephonyInfo?.networkCountry
            self.telephonyNetworkIsRoaming = telephonyInfo?.networkIsRoaming
            self.telephonyNetworkOperator = telephonyInfo?.networkOperator
            self.telephonyNetworkOperatorName = telephonyInfo?.networkOperatorName
            self.telephonyNetworkSimCountry = telephonyInfo?.networkSimCountry
            self.telephonyNetworkSimOperator = telephonyInfo?.networkSimOperator
            self.telephonyNetworkSimOperatorName = telephonyInfo?.networkSimOperatorName
            self.telephonyPhoneType = telephonyInfo?.phoneType
        }
    }

    var telephonyDataState: Int?
    var telephonyNetworkCountry: String?
    var telephonyNetworkIsRoaming: Bool?
    var telephonyNetworkOperator: String?
    var telephonyNetworkOperatorName: String?
    var telephonyNetworkSimCountry: String?
    var telephonyNetworkSimOperator: String?
    var telephonyNetworkSimOperatorName: String?
    var telephonyPhoneType: Int?
    
    ///WiFi Info Properties
    var wifiInfo: WifiInfo? {
        didSet {
            self.wifiSsid = wifiInfo?.ssid
            self.wifiBssid = wifiInfo?.bssid
            self.wifiNetworkId = wifiInfo?.networkId
            self.wifiSupplicantState = wifiInfo?.supplicantState
            self.wifiSupplicantStateDetail = wifiInfo?.supplicantStateDetail
        }
    }
    
    var wifiSsid: String?
    var wifiBssid: String?
    var wifiNetworkId: String?
    var wifiSupplicantState: String?
    var wifiSupplicantStateDetail: String?
    
    
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
//            telephonyInfo       <- map["telephony_info"]
//            wifiInfo            <- map["wifi_info"]
        //Telephony Info Properties
            telephonyDataState <- map["telephony_data_state"]
            telephonyNetworkCountry <- map["telephony_network_country"]
            telephonyNetworkIsRoaming <- map["telephony_network_is_roaming"]
            telephonyNetworkOperator <- map["telephony_network_operator"]
            telephonyNetworkOperatorName <- map["telephony_network_operator_name"]
            telephonyNetworkSimCountry <- map["telephony_network_sim_country"]
            telephonyNetworkSimOperator <- map["telephony_network_sim_operator"]
            telephonyNetworkSimOperatorName <- map["telephony_network_sim_operator_name"]
            telephonyPhoneType <- map["telephony_phone_type"]

        //WiFi Info Properties
            wifiSsid <- map["wifi_ssid"]
            wifiBssid <- map["wifi_bssid"]
            wifiNetworkId <- map["wifi_network_id"]
            wifiSupplicantState <- map["wifi_supplicant_state"]
            wifiSupplicantStateDetail <- map["wifi_supplicant_state_detail"]
        
            cellLocations       <- map["cellLocations"]
        #endif
    }
    
    class func submit(zeroMeasurements: [ZeroMeasurementRequest], success: @escaping (_ response: SpeedMeasurementSubmitResponse) -> (), error failure: @escaping ErrorCallback) {
        let controlServer = ControlServer.sharedControlServer
        
        controlServer.submitZeroMeasurementRequests(zeroMeasurements, success: success, error: failure)
    }
}

