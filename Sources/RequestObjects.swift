//
//  RequestObjects.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 31.05.16.
//
//

import Foundation
import ObjectMapper
import CoreLocation

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
    var client: ClientSettings?

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
    init(location: CLLocation) {
        latitude        = location.coordinate.latitude
        longitude       = location.coordinate.longitude
        accuracy        = location.horizontalAccuracy
        altitude        = location.altitude
        bearing         = location.course
        speed           = (location.speed > 0.0 ? location.speed : 0.0)
        provider        = "GPS" // TODO?
        relativeTimeNs  = 0 // TODO?
        time            = location.timestamp // TODO?
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
    var cpuUsage = TestStat()

    ///
    var memUsage = TestStat()

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
    var networkType: String? // result only

    ///
    var networkTypeId = -1

    ///
    var catTechnology: String? // results only

    ///
    var time: NSDate?

    ///
    var signalStrength: Int?

    ///
    var wifiLinkSpeed: Int? // http://stackoverflow.com/questions/16878982/ios-get-link-speed-router-speed-test

    ///
    var wifiRssi: Int? // not available on iOS

    ///
    var gsmBitErrorRate: Int? // not available on iOS

    ///
    var lteRsrp: Int? // not available on iOS

    ///
    var lteRsrq: Int? // not available on iOS

    ///
    var lteRssnr: Int? // not available on iOS

    ///
    var lteCqi: Int? // not available on iOS

    ///
    init() {

    }

    ///
    init(connectivity: RMBTConnectivity) {
        // TODO: additional fields?

        relativeTimeNs = RMBTTimestampWithNSDate(connectivity.timestamp).integerValue
        time = connectivity.timestamp

        if connectivity.networkType == .Cellular {
            networkTypeId = connectivity.cellularCode.integerValue
        } else {
            networkTypeId = connectivity.networkType.rawValue
        }
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
    init(connectivity: RMBTConnectivity) {
        networkOperatorName = connectivity.networkName ?? "Unknown"
        networkSimOperator = connectivity.telephonyNetworkSimOperator
        networkSimCountry = connectivity.telephonyNetworkSimCountry
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
    init(connectivity: RMBTConnectivity) {
        ssid = connectivity.networkName ?? "Unknown"
        bssid = connectivity.bssid
        networkId = "\(connectivity.networkType.rawValue)" // TODO: why is this a string?
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
class SpeedMeasurementResult: BasicRequest {

    ///
    var uuid: String?

    ///
    var clientUuid: String?

    ///
    var extendedTestStat = ExtendedTestStat()

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

    ///////////

    ///
    let resolutionNanos: UInt64

    ///
    var testStartNanos: UInt64 = 0

    ///
    var testStartDate: NSDate?

    ///
    var bestPingNanos: UInt64 = 0

    ///
    var medianPingNanos: UInt64 = 0

    /////

    ///
    private var maxFrozenPeriodIndex: Int!

    ///
    let totalDownloadHistory: RMBTThroughputHistory

    ///
    let totalUploadHistory: RMBTThroughputHistory

    ///
    weak var totalCurrentHistory: RMBTThroughputHistory!

    ///
    var currentHistories: NSMutableArray!//[RMBTThroughputHistory]!

    ///
    var perThreadDownloadHistories: NSMutableArray!//[RMBTThroughputHistory]()

    ///
    var perThreadUploadHistories: NSMutableArray!//[RMBTThroughputHistory]()

    ///
    private var connectivities = [RMBTConnectivity]()

    ////////////

    ///
    init(resolutionNanos nanos: UInt64) {
        self.resolutionNanos = nanos

        self.totalDownloadHistory = RMBTThroughputHistory(resolutionNanos: nanos)
        self.totalUploadHistory = RMBTThroughputHistory(resolutionNanos: nanos)

        super.init()
    }

    ///
    required init?(_ map: Map) {
        fatalError("init has not been implemented")
    }

    //////////

    ///
    func addLength(length: UInt64, atNanos ns: UInt64, forThreadIndex threadIndex: Int) -> [RMBTThroughput]! {
        assert(threadIndex >= 0 && threadIndex < numThreads, "Invalid thread index")

        let h = currentHistories.objectAtIndex(threadIndex) as! RMBTThroughputHistory//currentHistories[threadIndex]
        h.addLength(length, atNanos: ns)

        // TODO: optimize calling updateTotalHistory only when certain preconditions are met

        return updateTotalHistory()
    }

    /// Returns array of throughputs in intervals for which all threads have reported speed
    private func updateTotalHistory() -> [RMBTThroughput]! { // TODO: distinguish between download/upload thread counts
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
            if i == commonFrozenPeriodIndex && (currentHistories.objectAtIndex(0) as! RMBTThroughputHistory).isFrozen { //currentHistories[0].isFrozen) {
                // We're adding up the last throughput, clip totals according to spec
                // 1) find t*
                var minEndNanos: UInt64 = 0
                var minPeriodIndex: UInt64 = 0

                for threadIndex in 0 ..< numThreads {
                    let threadHistory = currentHistories.objectAtIndex(threadIndex) as! RMBTThroughputHistory //currentHistories[threadIndex]
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

                totalCurrentHistory.addLength(length, atNanos: minEndNanos)
            } else {
                var length: UInt64 = 0

                for threadIndex in 0 ..< numThreads {
                    let tt = (currentHistories[threadIndex] as! RMBTThroughputHistory).periods[i]
                    length += tt.length

                    assert(totalCurrentHistory.totalThroughput.endNanos == tt.startNanos, "Period start time mismatch")
                }

                totalCurrentHistory.addLength(length, atNanos: UInt64(i + 1) * resolutionNanos)
            }
        }

        let result = (totalCurrentHistory.periods as NSArray).subarrayWithRange(
            NSRange(location: maxFrozenPeriodIndex + 1, length: commonFrozenPeriodIndex - maxFrozenPeriodIndex)
            ) as! [RMBTThroughput]
        //var result = Array(totalCurrentHistory.periods[Int(maxFrozenPeriodIndex + 1)...Int(commonFrozenPeriodIndex - maxFrozenPeriodIndex)])
        // TODO: why is this not optional? does this return an empty array? see return statement

        maxFrozenPeriodIndex = commonFrozenPeriodIndex

        return result.count > 0 ? result : nil
    }

    //////////

    ///
    func startDownloadWithThreadCount(threadCount: Int) {
        numThreads = threadCount

        perThreadDownloadHistories = NSMutableArray(capacity: threadCount)
        perThreadUploadHistories = NSMutableArray(capacity: threadCount)

        for _ in 0 ..< threadCount {
            perThreadDownloadHistories.addObject(RMBTThroughputHistory(resolutionNanos: resolutionNanos))
            perThreadUploadHistories.addObject(RMBTThroughputHistory(resolutionNanos: resolutionNanos))
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

        totalCurrentHistory.freeze()

        let totalPeriodCount = totalCurrentHistory.periods.count

        totalCurrentHistory.squashLastPeriods(1)

        // Squash last two periods in all histories
        for h in currentHistories {
            (h as! RMBTThroughputHistory).squashLastPeriods(1 + ((h as! RMBTThroughputHistory).periods.count - totalPeriodCount))
        }

        // Remove last measurement from result, as we don't want to plot that one as it's usually too short
        if result.count > 0 {
            result = Array(result[0..<(result.count - 1)])
        }

        return result
    }

    //////

    ///
    func addConnectivity(connectivity: RMBTConnectivity) {
        connectivities.append(connectivity)
    }

    ///
    func lastConnectivity() -> RMBTConnectivity! {
        return connectivities.last
    }

    //////////

    ///
    func markTestStart() {
        testStartNanos = RMBTCurrentNanos()
        testStartDate = NSDate()
    }

    ///
    func addPingWithServerNanos(serverNanos: UInt64, clientNanos: UInt64) {
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
        let sortedPings = pings.sort { (p1: Ping, p2: Ping) -> Bool in
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
    func addLocation(location: CLLocation) {
        let geoLocation = GeoLocation(location: location)
        //geoLocation.relativeTimeNs =
        geoLocations.append(geoLocation)
    }

    ///
    func addCpuUsage(cpuUsage: Double, atNanos ns: Int) {
        let cpuStatValue = ExtendedTestStat.TestStat.TestStatValue()

        cpuStatValue.value = cpuUsage
        cpuStatValue.timeNs = ns

        extendedTestStat.cpuUsage.values.append(cpuStatValue)
    }

    ///
    func addMemoryUsage(ramUsage: Double, atNanos ns: Int) {
        let memStatValue = ExtendedTestStat.TestStat.TestStatValue()

        memStatValue.value = ramUsage
        memStatValue.timeNs = ns

        extendedTestStat.memUsage.values.append(memStatValue)
    }

    /////////

    ///
    func calculateThreadThroughputs(perThreadArray: /*[RMBTThroughputHistory]*/NSArray, direction: SpeedRawItem.SpeedRawItemDirection) {

        for i in 0 ..< perThreadArray.count {
            let h = perThreadArray.objectAtIndex(i)/*[i]*/ as! RMBTThroughputHistory
            var totalLength: UInt64 = 0

            for t in h.periods {
                totalLength += t.length

                let speedRawItem = SpeedRawItem()

                speedRawItem.direction = direction
                speedRawItem.thread = i
                speedRawItem.time = Int(t.endNanos)
                speedRawItem.bytes = Int(totalLength)

                speedDetail.append(speedRawItem)
            }
        }
    }

    ///
    func calculate() {
        calculateThreadThroughputs(perThreadDownloadHistories, direction: .Download)
        calculateThreadThroughputs(perThreadUploadHistories, direction: .Upload)

        // download total troughputs
        speedDownload = Int(totalDownloadHistory.totalThroughput.kilobitsPerSecond())
        durationDownloadNs = Int(totalDownloadHistory.totalThroughput.endNanos)
        bytesDownload = Int(totalDownloadHistory.totalThroughput.length)

        // upload total troughputs
        speedUpload = Int(totalUploadHistory.totalThroughput.kilobitsPerSecond())
        durationUploadNs = Int(totalUploadHistory.totalThroughput.endNanos)
        bytesUpload = Int(totalUploadHistory.totalThroughput.length)

        // connectivities
        for c in connectivities {
            let s = Signal(connectivity: c)
            signals.append(s)

            networkType = max(networkType ?? -1, s.networkTypeId)
        }

        // TODO: is it correct to get telephony/wifi info from lastConnectivity?
        if let lastConnectivity = lastConnectivity() {
            if lastConnectivity.networkType == .Cellular {
                telephonyInfo = TelephonyInfo(connectivity: lastConnectivity)
            } else if lastConnectivity.networkType == .WiFi {
                wifiInfo = WifiInfo(connectivity: lastConnectivity)
            }
        }
    }

    /////////

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

    ///
    var clientUuid: String?

    ///
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
