/*****************************************************************************************************
 * Copyright 2016 SPECURE GmbH
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *****************************************************************************************************/

import Foundation
import ObjectMapper
import CoreLocation
import RealmSwift

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}


///
class SpeedMeasurementResult: BasicRequest {

    var isDualSim: Bool = false // TODO: Implement it
    var geoLocations: [GeoLocation] = []
    var networkType: Int?
    var pings: [Ping] = []
    var speedDetail: [SpeedRawItem] = []
    
    var loopMode: Bool?
    var userServerSelection: Bool?

    var jpl: SpeedMeasurementJPLResult? {
        didSet {
            if let inJiter = jpl?.resultOutMeanJitter,
               let outJiter = jpl?.resultInMeanJitter {
                self.jitter = String(format: "%.1f", Double(inJiter + outJiter) / 2_000_000)
            }
            
            // compute packet loss (both directions) as outcome
            if let inPL = jpl?.resultInNumPackets,
               let outPL = jpl?.resultOutNumPackets,
               let objDelay = jpl?.objectiveDelay,
               let objCallDuration = jpl?.objectiveCallDuration,
                objDelay != 0,
                objCallDuration != 0 {

                let total = Double(objCallDuration) / Double(objDelay)

                let packetLossUp = (total - Double(outPL)) / total
                let packetLossDown = (total - Double(inPL)) / total

                self.packetLoss = String(format: "%0.1f", ((packetLossUp + packetLossDown) / 2) * 100)
            }
        }
    }
    

    ///
    var clientUuid: String?

    ///
    var extendedTestStat = ExtendedTestStat()

    var jitter: String?
    
    var packetLoss: String?
    
    var bytesDownload: UInt64?

    ///
    var bytesUpload: UInt64?

    ///
    var encryption: String?

    ///
    var ipLocal: String?

    ///
    var ipServer: String?

    ///
    var durationUploadNs: UInt64?

    ///
    var durationDownloadNs: UInt64?

    ///
    var numThreads = 1

    ///
    var numThreadsUl = 1

    ///
    var pingShortest: Int? {
        get {
            return Int(bestPingNanos)
        }
        set {
            // do nothing
        }
    }

    ///
    var portRemote: Int?

    ///
    var speedDownload: UInt64?

    ///
    var speedUpload: UInt64?

    ///
    var token: String?

    ///
    var totalBytesDownload: Int?

    ///
    var totalBytesUpload: Int?

    ///
    var interfaceTotalBytesDownload = 0

    ///
    var interfaceTotalBytesUpload = 0

    ///
    var interfaceDltestBytesDownload = 0

    ///
    var interfaceDltestBytesUpload = 0

    ///
    var interfaceUltestBytesDownload = 0

    ///
    var interfaceUltestBytesUpload = 0

    ///
    var time: Date?

    ///
    var relativeTimeDlNs: Int?

    ///
    var relativeTimeUlNs: Int?

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
    
    ///
    //var cellLocations = [CellLocation]()

    #endif

    ///
    var publishPublicData = true

    ///
    var tag: String?

    ///////////

    ///
    var resolutionNanos: UInt64 = 0

    ///
    var testStartNanos: UInt64 = 0

    ///
    var testStartDate: Date?

    ///
    var bestPingNanos: UInt64 = 0

    ///
    var medianPingNanos: UInt64 = 0

    /////

    ///
    fileprivate var maxFrozenPeriodIndex: Int!

    ///
    let totalDownloadHistory: RMBTThroughputHistory

    ///
    let totalUploadHistory: RMBTThroughputHistory

    ///
    var totalCurrentHistory: RMBTThroughputHistory?

    ///
    var currentHistories: NSMutableArray!//[RMBTThroughputHistory]!

    ///
    var perThreadDownloadHistories: NSMutableArray!//[RMBTThroughputHistory]()

    ///
    var perThreadUploadHistories: NSMutableArray!//[RMBTThroughputHistory]()

    ///
    fileprivate var connectivities = [RMBTConnectivity]()

    ////////////

    ///
    init(resolutionNanos nanos: UInt64) {
        self.resolutionNanos = nanos

        self.totalDownloadHistory = RMBTThroughputHistory(resolutionNanos: nanos)
        self.totalUploadHistory = RMBTThroughputHistory(resolutionNanos: nanos)

        super.init()
    }

    ///
    required public init?(map: Map) {
        let nanos = self.resolutionNanos
        self.totalDownloadHistory = RMBTThroughputHistory(resolutionNanos: nanos)
        self.totalUploadHistory = RMBTThroughputHistory(resolutionNanos: nanos)
        super.init(map: map)
    }

    //////////

    ///
    func addLength(_ length: UInt64, atNanos ns: UInt64, forThreadIndex threadIndex: Int) -> [RMBTThroughput]! {
        assert(threadIndex >= 0 && threadIndex < numThreads, "Invalid thread index")

        let h = currentHistories.object(at: threadIndex) as! RMBTThroughputHistory//currentHistories[threadIndex]
        h.addLength(length, atNanos: ns)

        // TODO: optimize calling updateTotalHistory only when certain preconditions are met

        return updateTotalHistory()
    }

    /// Returns array of throughputs in intervals for which all threads have reported speed
    fileprivate func updateTotalHistory() -> [RMBTThroughput]! { // TODO: distinguish between download/upload thread counts
        var commonFrozenPeriodIndex = Int.max

        for h in currentHistories {
            commonFrozenPeriodIndex = min(commonFrozenPeriodIndex, (h as! RMBTThroughputHistory).lastFrozenPeriodIndex)
        }

        // TODO: assert ==
        if commonFrozenPeriodIndex == Int.max || commonFrozenPeriodIndex <= maxFrozenPeriodIndex {
            return nil
        }

        for i in maxFrozenPeriodIndex + 1...commonFrozenPeriodIndex {
            //for var i = maxFrozenPeriodIndex + 1; i <= commonFrozenPeriodIndex; i += 1 {
            if i == commonFrozenPeriodIndex && (currentHistories.object(at: 0) as! RMBTThroughputHistory).isFrozen { //currentHistories[0].isFrozen) {
                // We're adding up the last throughput, clip totals according to spec
                // 1) find t*
                var minEndNanos: UInt64 = 0
                var minPeriodIndex: UInt64 = 0

                for threadIndex in 0 ..< numThreads {
                    let threadHistory = currentHistories.object(at: threadIndex) as! RMBTThroughputHistory //currentHistories[threadIndex]
                    assert(threadHistory.isFrozen)

                    let threadLastFrozenPeriodIndex = threadHistory.lastFrozenPeriodIndex

                    let threadLastTput = threadHistory.periods[threadLastFrozenPeriodIndex]
                    if minEndNanos == 0 || threadLastTput.endNanos < minEndNanos {
                        minEndNanos = threadLastTput.endNanos
                        minPeriodIndex = UInt64(threadLastFrozenPeriodIndex)
                    }
                }

                // 2) Add up bytes in proportion to t*
                var length: UInt64 = 0

                for threadIndex in 0 ..< numThreads {
                    let threadLastPut = (currentHistories[threadIndex] as! RMBTThroughputHistory).periods[Int(minPeriodIndex)]
                    // Factor = (t*-t(k,m-1)/t(k,m)-t(k,m-1))
                    let factor = Double(minEndNanos - threadLastPut.startNanos) / Double(threadLastPut.durationNanos)

                    assert(factor >= 0.0 && factor <= 1.0, "Invalid factor")

                    length += UInt64(factor) * threadLastPut.length
                }

                totalCurrentHistory?.addLength(length, atNanos: minEndNanos)
            } else {
                var length: UInt64 = 0

                for threadIndex in 0 ..< numThreads {
                    let tt = (currentHistories[threadIndex] as! RMBTThroughputHistory).periods[i]
                    length += tt.length

                    assert(totalCurrentHistory?.totalThroughput.endNanos == tt.startNanos, "Period start time mismatch")
                }

                totalCurrentHistory?.addLength(length, atNanos: UInt64(i + 1) * resolutionNanos)
            }
        }

        let result = (totalCurrentHistory?.periods as NSArray?)?.subarray(
            with: NSRange(location: maxFrozenPeriodIndex + 1,
                          length: commonFrozenPeriodIndex - maxFrozenPeriodIndex)
            ) as? [RMBTThroughput]
        //var result = Array(totalCurrentHistory.periods[Int(maxFrozenPeriodIndex + 1)...Int(commonFrozenPeriodIndex - maxFrozenPeriodIndex)])
        // TODO: why is this not optional? does this return an empty array? see return statement

        maxFrozenPeriodIndex = commonFrozenPeriodIndex

        return result?.count ?? 0 > 0 ? result : nil
    }

    //////////

    ///
    func startDownloadWithThreadCount(_ threadCount: Int) {
        numThreads = threadCount

        perThreadDownloadHistories = NSMutableArray(capacity: threadCount)
        perThreadUploadHistories = NSMutableArray(capacity: threadCount)

        for _ in 0 ..< threadCount {
            perThreadDownloadHistories.add(RMBTThroughputHistory(resolutionNanos: resolutionNanos))
            perThreadUploadHistories.add(RMBTThroughputHistory(resolutionNanos: resolutionNanos))
        }

        totalCurrentHistory = totalDownloadHistory // TODO: check pass by value on array
        currentHistories = perThreadDownloadHistories // TODO: check pass by value on array
        maxFrozenPeriodIndex = -1
    }

    /// Per spec has same thread count as download
    func startUpload() {
        numThreadsUl = numThreads // TODO: can upload threads be different from download threads?

        totalCurrentHistory = totalUploadHistory // TODO: check pass by value on array
        currentHistories = perThreadUploadHistories // TODO: check pass by value on array
        maxFrozenPeriodIndex = -1
    }

    /// Called at the end of each phase. Flushes out values to total history.
    func flush() -> [AnyObject]! {
        var result: [AnyObject]!// = [AnyObject]()

        for h in currentHistories {
            (h as! RMBTThroughputHistory).freeze()
        }

        result = updateTotalHistory()

        totalCurrentHistory?.freeze()

        let totalPeriodCount = totalCurrentHistory?.periods.count ?? 0

        totalCurrentHistory?.squashLastPeriods(1)

        // Squash last two periods in all histories
        for h in currentHistories {
            (h as! RMBTThroughputHistory).squashLastPeriods(1 + ((h as! RMBTThroughputHistory).periods.count - totalPeriodCount))
        }

        // Remove last measurement from result, as we don't want to plot that one as it's usually too short
//        if result.count > 0 {
//            result = Array(result[0..<(result.count - 1)])
//        }

        return result
    }

    //////

    ///
    func addConnectivity(_ connectivity: RMBTConnectivity) {
        connectivities.append(connectivity)
    }

    ///
    func lastConnectivity() -> RMBTConnectivity? {
        return connectivities.last
    }

    //////////

    ///
    func markTestStart() {
        testStartNanos = RMBTCurrentNanos()
        testStartDate = Date()
    }

    ///
    func addPingWithServerNanos(_ serverNanos: UInt64, clientNanos: UInt64) {
        assert(testStartNanos > 0)

        let ping = Ping(
            serverNanos: serverNanos,
            clientNanos: clientNanos,
            relativeTimestampNanos: RMBTCurrentNanos() - testStartNanos)

        pings.append(ping)

        if bestPingNanos == 0 || bestPingNanos > serverNanos {
            bestPingNanos = serverNanos
        }

        if bestPingNanos > clientNanos {
            bestPingNanos = clientNanos
        }

        // Take median from server pings as "best" ping
        let sortedPings = pings.sorted { (p1: Ping, p2: Ping) -> Bool in
            return p1.serverNanos < p2.serverNanos // TODO: is this correct?
        }

        let sortedPingsCount = sortedPings.count

        if sortedPingsCount % 2 == 1 {
            // Uneven number of pings, median is right in the middle
            let i = (sortedPingsCount - 1) / 2
            medianPingNanos = UInt64(sortedPings[i].serverNanos!)
        } else {
            // Even number of pings, median is defined as average of two middle elements
            let i = sortedPingsCount / 2
            medianPingNanos = (UInt64(sortedPings[i].serverNanos!) + UInt64(sortedPings[i - 1].serverNanos!)) / 2 // TODO: is division correct? should divisor be casted to double?
        }
    }

    ///
    func addLocation(_ location: CLLocation) {
        let geoLocation = GeoLocation(location: location)
        //geoLocation.relativeTimeNs =
        geoLocations.append(geoLocation)
    }

    ///
    func addCpuUsage(_ cpuUsage: Double, atNanos ns: UInt64) {
        let cpuStatValue = ExtendedTestStat.TestStat.TestStatValue()

        cpuStatValue.value = cpuUsage
        cpuStatValue.timeNs = ns

        extendedTestStat.cpuUsage.values.append(cpuStatValue)
    }

    ///
    func addMemoryUsage(_ ramUsage: Double, atNanos ns: UInt64) {
        let memStatValue = ExtendedTestStat.TestStat.TestStatValue()

        memStatValue.value = ramUsage
        memStatValue.timeNs = ns

        extendedTestStat.memUsage.values.append(memStatValue)
    }

    /////////

    ///
    func calculateThreadThroughputs(_ perThreadArray: /*[RMBTThroughputHistory]*/NSArray, direction: SpeedRawItem.SpeedRawItemDirection) {

        for i in 0 ..< perThreadArray.count {
            let h = perThreadArray.object(at: i)/*[i]*/ as! RMBTThroughputHistory
            var totalLength: UInt64 = 0

            for t in h.periods {
                totalLength += t.length

                let speedRawItem = SpeedRawItem()

                speedRawItem.direction = direction
                speedRawItem.thread = i
                speedRawItem.time = t.endNanos
                speedRawItem.bytes = totalLength

                speedDetail.append(speedRawItem)
            }
        }
    }

    ///
    func calculate() {
        if let perThreadDownloadHistories = perThreadDownloadHistories {
            calculateThreadThroughputs(perThreadDownloadHistories, direction: .Download)
        }
        if let perThreadUploadHistories = perThreadUploadHistories {
            calculateThreadThroughputs(perThreadUploadHistories, direction: .Upload)
        }

        // download total troughputs
        speedDownload = UInt64(totalDownloadHistory.totalThroughput.kilobitsPerSecond())
        durationDownloadNs = totalDownloadHistory.totalThroughput.endNanos
        bytesDownload = totalDownloadHistory.totalThroughput.length

        // upload total troughputs
        speedUpload = UInt64(totalUploadHistory.totalThroughput.kilobitsPerSecond())
        durationUploadNs = totalUploadHistory.totalThroughput.endNanos
        bytesUpload = totalUploadHistory.totalThroughput.length

        #if os(iOS)
        // connectivities
        for c in connectivities {
            let s = Signal(connectivity: c)
            signals.append(s)

            networkType = max(networkType ?? -1, s.networkTypeId)
        }

        // TODO: is it correct to get telephony/wifi info from lastConnectivity?
        if let lastConnectivity = lastConnectivity() {
            if lastConnectivity.networkType == .cellular {
                telephonyInfo = TelephonyInfo(connectivity: lastConnectivity)
            } else if lastConnectivity.networkType == .wiFi {
                wifiInfo = WifiInfo(connectivity: lastConnectivity)
            }
        }
        #else
        networkType = RMBTNetworkType.wiFi.rawValue // TODO: correctly set on macos and tvOS
        #endif
    }

    
    /////////

    ///
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        clientUuid              <- map["client_uuid"]
        isDualSim               <- map["dual_sim"] // TODO: //
        geoLocations            <- map["geoLocations"]
        networkType             <- map["network_type"]
        pings                   <- map["pings"]
        speedDetail             <- map["speed_detail"]
        
        totalBytesDownload      <- map["test_total_bytes_download"]
        totalBytesUpload        <- map["test_total_bytes_upload"]
        totalBytesDownload      <- map["test_bytes_download"]
        totalBytesUpload        <- map["test_bytes_upload"]
        interfaceDltestBytesDownload <- map["testdl_if_bytes_download"]
        interfaceDltestBytesUpload   <- map["testdl_if_bytes_upload"]
        interfaceUltestBytesDownload <- map["testul_if_bytes_download"]
        interfaceUltestBytesUpload   <- map["testul_if_bytes_upload"]
        
        encryption              <- map["test_encryption"]
        
        interfaceTotalBytesDownload  <- map["test_if_bytes_download"]
        interfaceTotalBytesUpload    <- map["test_if_bytes_upload"]
        
        ipLocal                 <- map["test_ip_local"]
        ipServer                <- map["test_ip_server"]
        portRemote              <- map["test_port_remote"]
        
        durationDownloadNs      <- (map["test_nsec_download"], UInt64NSNumberTransformOf)
        durationUploadNs        <- (map["test_nsec_upload"], UInt64NSNumberTransformOf)
        
        pingShortest            <- map["test_ping_shortest"]
        speedDownload           <- (map["test_speed_download"], UInt64NSNumberTransformOf)
        speedUpload             <- (map["test_speed_upload"], UInt64NSNumberTransformOf)
        jitter                  <-  map["voip_result_jitter_millis"] // TODO: //
        packetLoss              <- map["voip_result_packet_loss_percents"] // TODO: //
    
        time              <- (map["time"], DateMilisecondsTransformOf)
        
        token                   <- map["test_token"]
        relativeTimeDlNs  <- map["time_dl_ns"]
        relativeTimeUlNs  <- map["time_ul_ns"]
        
        loopMode <- map["user_loop_mode"] // TODO: //
        userServerSelection <- map["user_server_selection"] // TODO: //
        
//        jpl                     <- map["jpl"]
#if os(iOS)
        signals       <- map["signals"]
        
        telephonyDataState <- map["telephony_data_state"]
        telephonyNetworkCountry <- map["telephony_network_country"]
        telephonyNetworkIsRoaming <- map["telephony_network_is_roaming"]
        telephonyNetworkOperator <- map["telephony_network_operator"]
        telephonyNetworkOperatorName <- map["telephony_network_operator_name"]
        telephonyNetworkSimCountry <- map["telephony_network_sim_country"]
        telephonyNetworkSimOperator <- map["telephony_network_sim_operator"]
        telephonyPhoneType <- map["telephony_phone_type"]
        numThreads              <- map["test_num_threads"]
        
        //WiFi Info Properties
        wifiSsid <- map["wifi_ssid"]
        wifiBssid <- map["wifi_bssid"]
        wifiNetworkId <- map["wifi_network_id"]
        wifiSupplicantState <- map["wifi_supplicant_state"]
        wifiSupplicantStateDetail <- map["wifi_supplicant_state_detail"]
        
#endif
//        if RMBTConfig.sharedInstance.RMBT_VERSION_NEW {
//            extendedTestStat        <- map["extended_test_stat"]
//            publishPublicData <- map["publish_public_data"]
//        } else {
//            extendedTestStat        <- map["extended_test_stat"]
//            publishPublicData <- map["publish_public_data"]
//        }
    }
}


/*
 {
   "android_permission_status": [
     {
       "permission": "android.permission.ACCESS_FINE_LOCATION",
       "status": true
     }
   ],
   "api_level": "string",
   "capabilities": {
     "classification": {
       "count": 5
     },
     "qos": {
       "supports_info": true
     },
     "RMBThttp": true
   },
   "cellLocations": [
     {
       "primary_scrambling_code": 0,
       "time": 0,
       "time_ns": 0,
       "area_code": 0,
       "location_id": 0
     }
   ],
   "client_language": "string",
   "client_name": "RMBT",
   "client_software_version": "string",
   "client_uuid": "string",
   "client_version": "1.2.1",
   "developer_mode": true,
   "device": "string",
   
   "geoLocations": [
     {
       "geo_lat": 0,
       "geo_long": 0,
       "accuracy": 0,
       "altitude": 0,
       "bearing": 0,
       "speed": 0,
       "tstamp": "2021-09-22T11:28:23.984Z",
       "provider": "string"
     }
   ],
   
   "model": "string",
   "network_type": 0,
   "os_version": "string",
   "pings": [
     {
       "value": 0,
       "value_server": 0,
       "time_ns": 0
     }
   ],
   "plattform": "Android",
   "product": "string",
   "signals": [
     {
       "time": 1571665024591,
       "timezone": "Europe/Prague",
       "uuid": "68796996-5f40-11eb-ae93-0242ac130002"
     }
   ],
   "speed_detail": [
     {
       "direction": "download",
       "thread": 0,
       "time": 0,
       "bytes": 0
     }
   ],
   "telephony_data_state": 2,
   "telephony_network_country": "string",
   "telephony_network_is_roaming": true,
   "telephony_network_operator": "231-06",
   "telephony_network_operator_name": "O2 - SK",
   "telephony_network_sim_country": "sk",
   "telephony_network_sim_operator": "O2 - SK",
   "telephony_network_sim_operator_name": "O2 - SK",
   
   "telephony_phone_type": 1,
   "test_bytes_download": 0,
   "test_bytes_upload": 0,
   "test_encryption": "TLSv1.2 (TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256)",
   "test_if_bytes_download": 0,
   "test_if_bytes_upload": 0,
   "test_ip_local": "192.168.1.100",
   "test_ip_server": "81.16.157.221",
   "test_nsec_download": 0,
   "test_nsec_upload": 0,
   "test_num_threads": 0,
   "test_ping_shortest": 29783021,
   "test_port_remote": 0,
   "test_speed_download": 7170,
   "test_speed_upload": 15061,
   "test_token": "8628925b-eda5-4500-9bbc-365f592470ce_1614328561_Dggllgjl/4zMNl97cNab2wgUb8k=",
   "test_total_bytes_download": 0,
   "test_total_bytes_upload": 0,
   "testdl_if_bytes_download": 0,
   "testdl_if_bytes_upload": 0,
   "testul_if_bytes_download": 0,
   "testul_if_bytes_upload": 0,
   "time": 0,
   "time_dl_ns": 0,
   "time_ul_ns": 0,
   "user_loop_mode": true,
   "user_server_selection": true,
   "voip_result_jitter_millis": "string",
   "voip_result_packet_loss_percents": "string",
   "wifi_bssid": "string",
   "wifi_network_id": "string",
   "wifi_ssid": "string",
   "wifi_supplicant_state": "COMPLETED",
   "wifi_supplicant_state_detail": "OBTAINING_IPADDR"
 
 //Not implemented
 "dual_sim": true,
 "dual_sim_detection_method": "string",
 "last_client_status": "WAIT",
 "last_qos_status": "WAIT",
   "radioInfo": {
     "cells": [
       {
         "active": true,
         "area_code": 0,
         "location_id": 0,
         "mcc": 0,
         "mnc": 0,
         "primary_scrambling_code": 0,
         "registered": true,
         "technology": "G2",
         "uuid": "string",
         "channel_number": 0
       }
     ],
     "signals": [
       {
         "bit_error_rate": 0,
         "cell_uuid": "string",
         "network_type_id": 0,
         "signal": 0,
         "time_ns_last": 0,
         "time_ns": 0,
         "wifi_link_speed": 0,
         "lte_rsrp": 0,
         "lte_rsrq": 0,
         "lte_rssnr": 0,
         "lte_cqi": 0,
         "timing_advance": 0
       }
     ]
   },
 "tag": "string",
 "telephony_apn": "o2internet",
"telephony_nr_connection": "string",
"telephony_sim_count": 0,
"test_error_cause": "string",
"test_status": 0,
"test_submission_retry_count": 0,
 }
 */
