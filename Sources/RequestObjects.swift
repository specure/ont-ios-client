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
    
    var clientVersion: String? // TODO: fix this on server side
    
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
        language            <- map["client_language"] // TODO: fix this on server side
        
        model               <- map["model"]
        osVersion           <- map["os_version"]
        platform            <- map["platform"]
        product             <- map["product"]
        previousTestStatus  <- map["previous_test_status"]
        softwareRevision    <- map["software_revision"]
        
        softwareVersion     <- map["software_version"]
        softwareVersion     <- map["client_software_version"] // TODO: fix this on server side
        
        clientVersion       <- map["client_version"] // TODO: fix this on server side
        
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

class GeoLocation: Mappable {

    ///
    var latitude: Double?
    
    ///
    var longitude: Double?
    
    ///
    var accuracy: Double?
    
    ///
    var altitude: Double?

    ///
    var bearing: Double?

    ///
    var speed: Double?

    ///
    var provider: String?

    ///
    var relativeTimeNs: Int?
    
    ///
    var time: NSDate?
    
    ///
    init() {
        
    }
    
    ///
    required init?(_ map: Map) {
        
    }
    
    ///
    func mapping(map: Map) {
        latitude        <- map["latitude"]
        longitude       <- map["longitude"]
        accuracy        <- map["accuracy"]
        altitude        <- map["altitude"]
        bearing         <- map["bearing"]
        speed           <- map["speed"]
        provider        <- map["provider"]
        time            <- map["time"]
        relativeTimeNs  <- map["relative_time_ns"]
    }

}

///
class SpeedMeasurementRequest: BasicRequest {
    
    var uuid: String?
    
    var ndt: Bool? = false
    
    var time: Int?
    
    var version: String?
    
    var testCounter: UInt?
    
    var geoLocation: GeoLocation?
    
    ///
    override func mapping(map: Map) {
        super.mapping(map)
        
        uuid        <- map["uuid"]
        ndt         <- map["ndt"]
        time        <- map["time"]
        version     <- map["version"]
        testCounter <- map["test_counter"]
        
        geoLocation <- map["geo_location"]
    }
}

///
class ExtendedTestStat: Mappable {
    
    ///
    var cpuUsage: TestStat?
    
    ///
    var memUsage: TestStat?
    
    ///
    init() {
        
    }
    
    ///
    required init?(_ map: Map) {
        
    }
    
    ///
    func mapping(map: Map) {
        cpuUsage <- map["cpu_usage"]
        memUsage <- map["mem_usage"]
    }
    
    ///
    class TestStat: Mappable {
        
        ///
        var values = [TestStatValue]()
        
        ///
        var flags = [[String: AnyObject]]()
        
        ///
        init() {
            
        }
        
        ///
        required init?(_ map: Map) {
            
        }
        
        ///
        func mapping(map: Map) {
            values <- map["values"]
            flags <- map["flags"]
        }
        
        ///
        class TestStatValue: Mappable {
            
            ///
            var timeNs: Int?
            
            ///
            var value: Double?
            
            ///
            init() {
                
            }
            
            ///
            required init?(_ map: Map) {
                
            }
            
            ///
            func mapping(map: Map) {
                timeNs <- map["time_ns"]
                value <- map["value"]
            }
        }
    }
}

///
class MeasurementSpeedRawItem: Mappable {
    
    ///
    var thread: Int?
    
    ///
    var time: Int?
    
    ///
    var bytes: Int?
    
    ///
    init() {
        
    }
    
    ///
    required init?(_ map: Map) {
        
    }
    
    ///
    func mapping(map: Map) {
        thread  <- map["thread"]
        time    <- map["time"]
        bytes   <- map["bytes"]
    }
}

///
class SpeedRawItem: MeasurementSpeedRawItem {
    
    ///
    var direction: SpeedRawItemDirection?
    
    ///
    override func mapping(map: Map) {
        super.mapping(map)
        
        direction  <- map["direction"]
    }
    
    ///
    enum SpeedRawItemDirection: String {
        case Download = "download"
        case Upload = "upload"
    }
}

///
class Signal: Mappable {
    
    ///
    var relativeTimeNs: Int?
    
    ///
    var networkType: String?
    
    ///
    var networkTypeId: Int?

    ///
    var catTechnology: String?

    ///
    var time: NSDate?

    ///
    var signalStrength: Int?

    ///
    var wifiLinkSpeed: Int?
    
    ///
    var wifiRssi: Int?

    ///
    var gsmBitErrorRate: Int?

    ///
    var lteRsrp: Int?

    ///
    var lteRsrq: Int?
    
    ///
    var lteRssnr: Int?

    ///
    var lteCqi: Int?
    
    ///
    init() {
        
    }
    
    ///
    required init?(_ map: Map) {
        
    }
    
    ///
    func mapping(map: Map) {
        relativeTimeNs  <- map["relative_time_ns"]
        networkType     <- map["network_type"]
        networkTypeId   <- map["network_type_id"]
        catTechnology   <- map["cat_technology"]
        time            <- map["time"]
        signalStrength  <- map["signal_strength"]
        wifiLinkSpeed   <- map["wifi_link_speed"]
        wifiRssi        <- map["wifi_rssi"]
        gsmBitErrorRate <- map["gsm_bit_error_rate"]
        lteRsrp         <- map["lte_rsrp"]
        lteRsrq         <- map["lte_rsrq"]
        lteRssnr        <- map["lte_rssnr"]
        lteCqi          <- map["lte_cqi"]
    }
}

///
class TelephonyInfo: Mappable {
    
    ///
    var dataState: Int?
    
    ///
    var networkCountry: String?
    
    ///
    var networkIsRoaming: Bool?
    
    ///
    var networkOperator: String?
    
    ///
    var networkOperatorName: String?
    
    ///
    var networkSimCountry: String?
    
    ///
    var networkSimOperator: String?
    
    ///
    var networkSimOperatorName: String?
    
    ///
    var phoneType: Int?
    
    ///
    init() {
        
    }
    
    ///
    required init?(_ map: Map) {
        
    }
    
    ///
    func mapping(map: Map) {
        dataState           <- map["data_state"]
        networkCountry      <- map["network_country"]
        networkIsRoaming    <- map["network_is_roaming"]
        
        networkOperator     <- map["network_operator"]
        networkOperatorName <- map["network_operator_name"]
        
        networkSimCountry       <- map["network_sim_country"]
        networkSimOperator      <- map["network_sim_operator"]
        networkSimOperatorName  <- map["network_sim_operator_name"]
        phoneType               <- map["phone_type"]
    }
}

///
class WifiInfo: Mappable {
    
    ///
    var ssid: String?
    
    ///
    var bssid: String?
    
    ///
    var networkId: String?
    
    ///
    var supplicantState: String?
    
    ///
    var supplicantStateDetail: String?

    ///
    init() {
        
    }
    
    ///
    required init?(_ map: Map) {
        
    }
    
    ///
    func mapping(map: Map) {
        ssid        <- map["ssid"]
        bssid       <- map["bssid"]
        networkId   <- map["network_id"]
        supplicantState         <- map["supplicant_state"]
        supplicantStateDetail   <- map["supplicant_state_detail"]
    }
}

///
class SpeedMeasurementResultRequest: BasicRequest {
    
    ///
    var uuid: String?
    
    ///
    var clientUuid: String?

    ///
    var extendedTestStat: ExtendedTestStat?

    ///
    var geoLocations = [GeoLocation]()

    ///
    var networkType: Int?
    
    ///
    var pings = [Ping]()
    
    ///
    var signals = [Signal]()
    
    ///
    var speedDetail = [SpeedRawItem]()
    
    ///
    var bytesDownload: Int?

    ///
    var bytesUpload: Int?

    ///
    var encryption: String?
    
    ///
    var ipLocal: String?

    ///
    var ipServer: String?

    ///
    var durationUploadNs: Int?
    
    ///
    var durationDownloadNs: Int?
    
    ///
    var numThreads: Int?
    
    ///
    var numThreadsUl: Int?

    ///
    var pingShortest: Int?
    
    ///
    var portRemote: Int?
    
    ///
    var speedDownload: Int?

    ///
    var speedUpload: Int?

    ///
    var token: String?
    
    ///
    var totalBytesDownload: Int?

    ///
    var totalBytesUpload: Int?

    ///
    var interfaceTotalBytesDownload: Int?

    ///
    var interfaceTotalBytesUpload: Int?
    
    ///
    var interfaceDltestBytesDownload: Int?
    
    ///
    var interfaceDltestBytesUpload: Int?

    ///
    var interfaceUltestBytesDownload: Int?

    ///
    var interfaceUltestBytesUpload: Int?
    
    ///
    var time: NSDate?
    
    ///
    var relativeTimeDlNs: Int?

    ///
    var relativeTimeUlNs: Int?

    ///
    var telephonyInfo: TelephonyInfo?
    
    ///
    var wifiInfo: WifiInfo?
    
    ///
    //var cellLocations = [CellLocation]()
    
    ///
    var publishPublicData = true

    ///
    var tag: String?
    
    ///
    override func mapping(map: Map) {
        super.mapping(map)
        
        uuid                    <- map["uuid"]
        clientUuid              <- map["client_uuid"]
        extendedTestStat        <- map["extended_test_stat"]
        geoLocations            <- map["geo_locations"]
        networkType             <- map["network_type"]
        pings                   <- map["pings"]
        signals                 <- map["signals"]
        
        speedDetail             <- map["speed_detail"]
        bytesDownload           <- map["bytes_download"]
        bytesUpload             <- map["bytes_upload"]
        encryption              <- map["encryption"]
        ipLocal                 <- map["ip_local"]
        ipServer                <- map["ip_server"]
        durationUploadNs        <- map["duration_upload_ns"]
        durationDownloadNs      <- map["duration_download_ns"]
        numThreads              <- map["num_threads"]
        numThreadsUl            <- map["num_threads_ul"]
        pingShortest            <- map["ping_shortest"]
        portRemote              <- map["port_remote"]
        speedDownload           <- map["speed_download"]
        speedUpload             <- map["speed_upload"]
        
        token                   <- map["token"]
        totalBytesDownload      <- map["total_bytes_download"]
        totalBytesUpload        <- map["total_bytes_upload"]
        interfaceTotalBytesDownload  <- map["interface_total_bytes_download"]
        interfaceTotalBytesUpload    <- map["interface_total_bytes_upload"]
        interfaceDltestBytesDownload <- map["interface_dltest_bytes_download"]
        interfaceDltestBytesUpload   <- map["interface_dltest_bytes_upload"]
        interfaceUltestBytesDownload <- map["interface_ultest_bytes_download"]
        interfaceUltestBytesUpload   <- map["interface_ultest_bytes_upload"]
        
        time              <- map["time"]
        relativeTimeDlNs  <- map["relative_time_dl_ns"]
        relativeTimeUlNs  <- map["relative_time_ul_ns"]
        telephonyInfo     <- map["telephony_info"]
        wifiInfo          <- map["wifi_info"]
        //cellLocations   <- map["cell_locations"]
        publishPublicData <- map["publish_public_data"]
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

///
class QosMeasurementResultRequest: BasicRequest {
    
    ///
    var measurementUuid: String?
    
    ///
    var clientUuid: String?
    
    ///
    var testToken: String?
    
    ///
    var time: Int?
    
    ///
    var qosResultList: [QOSTestResults]?
    
    ///
    override func mapping(map: Map) {
        super.mapping(map)
        
        measurementUuid <- map["uuid"]
        clientUuid      <- map["client_uuid"]
        
        testToken       <- map["test_token"]
        
        time            <- map["time"]
        
        qosResultList   <- map["qos_result"]
    }
}
