/*****************************************************************************************************
 * Copyright 2013 appscape gmbh
 * Copyright 2014-2016 SPECURE GmbH
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
#if os(iOS)
import CoreTelephony
import NetworkExtension
#endif
import SystemConfiguration.CaptiveNetwork

///
open class RMBTConnectivity: NSObject {

    ///
    public let networkType: RMBTNetworkType

    ///
    public let timestamp: Date

    ///
    open var networkTypeDescription: String {
        switch networkType {
        case .none:
            return NSLocalizedString("connectivity.not-connected", tableName: nil, bundle: Bundle.main, value: "Not connected", comment: "network type description not connected")
        case .wiFi:
            return NSLocalizedString("connectivity.wifi", tableName: nil, bundle: Bundle.main, value: "Wi-Fi", comment: "network type description wifi")
        case .cellular:
            if cellularCodeDescription != nil {
                return cellularCodeDescription
            } else {
                return NSLocalizedString("connectivity.cellular", tableName: nil, bundle: Bundle.main, value: "Cellular", comment: "network type description cellular")
            }
        default:
            Log.logger.warning("Invalid network type \(self.networkType)")
            return NSLocalizedString("intro.network.connection.name-unknown", tableName: nil, bundle: Bundle.main, value: "Unknown", comment: "network type description unknown")
        }
    }

    ///
    open var networkName: String!

    ///
    open var bssid: String!

    ///
    var cellularCode: Int?

    ///
    var cellularCodeDescription: String!

    ///
    open var telephonyNetworkSimOperator: String!

    ///
    open var telephonyNetworkSimCountry: String!

    #if os(iOS)

    ///
    fileprivate var cellularCodeTable: [String: Int] {
        //https://specure.atlassian.net/wiki/spaces/NT/pages/144605185/Network+types
        var table = [
            CTRadioAccessTechnologyGPRS:         1,
            CTRadioAccessTechnologyEdge:         2,
            CTRadioAccessTechnologyWCDMA:        3,
            CTRadioAccessTechnologyCDMA1x:       4,
            CTRadioAccessTechnologyCDMAEVDORev0: 5,
            CTRadioAccessTechnologyCDMAEVDORevA: 6,
            CTRadioAccessTechnologyHSDPA:        8,
            CTRadioAccessTechnologyHSUPA:        9,
            CTRadioAccessTechnologyCDMAEVDORevB: 12,
            CTRadioAccessTechnologyLTE:          13,
            CTRadioAccessTechnologyeHRPD:        14
        ]
        
        if #available(iOS 14.1, *) {
            table[CTRadioAccessTechnologyNRNSA] = 41
            table[CTRadioAccessTechnologyNR] = 20
        }
        return table
    }

    ///
    fileprivate var cellularCodeDescriptionTable: [String: String] {
        var table = [
            CTRadioAccessTechnologyGPRS:            "GPRS (2G)",
            CTRadioAccessTechnologyEdge:            "EDGE (2G)",
            CTRadioAccessTechnologyWCDMA:           "UMTS (3G)",
            CTRadioAccessTechnologyCDMA1x:          "CDMA (2G)",
            CTRadioAccessTechnologyCDMAEVDORev0:    "EVDO0 (2G)",
            CTRadioAccessTechnologyCDMAEVDORevA:    "EVDOA (2G)",
            CTRadioAccessTechnologyHSDPA:           "HSDPA (3G)",
            CTRadioAccessTechnologyHSUPA:           "HSUPA (3G)",
            CTRadioAccessTechnologyCDMAEVDORevB:    "EVDOB (2G)",
            CTRadioAccessTechnologyLTE:             "LTE (4G)",
            CTRadioAccessTechnologyeHRPD:           "HRPD (2G)",
        ]
        
        if #available(iOS 14.1, *) {
            table[CTRadioAccessTechnologyNRNSA] = "NRNSA (5G)"
            table[CTRadioAccessTechnologyNR] = "NR (5G)"
        }
        
        return table
    }
    #endif

    ///
    public init(networkType: RMBTNetworkType) {
        self.networkType = networkType
        timestamp = Date()
        super.init()
        getNetworkDetails()
    }

// MARK: Internal

    ///
    open func getNetworkDetails() {
        networkName = nil
        bssid = nil
        cellularCode = nil
        cellularCodeDescription = nil

        switch networkType {

        case .cellular:
            updateCellularInfo()
        case .wiFi:
            // If WLAN, then show SSID as network name. Fetching SSID does not work on the simulator.
            if let wifiParams = getWiFiParameters() {
                networkName = wifiParams.ssid
                bssid = wifiParams.bssid
            }

            break

        case .none:
            break
        default:
            assert(false, "Invalid network type \(networkType)")
        }
    }

    fileprivate func getNetworkInfo(for carrier: CTCarrier) -> (networkName: String?, telephonyNetworkSimCountry: String?, telephonyNetworkSimOperator: String?) {
        let networkName = carrier.carrierName
        let telephonyNetworkSimCountry = carrier.isoCountryCode
        var codes: [String] = []
        if let mobileCountryCode = carrier.mobileCountryCode {
            codes.append(mobileCountryCode)
        }
        if let mobileNetworkCode = carrier.mobileNetworkCode {
            codes.append(mobileNetworkCode)
        }
        let telephonyNetworkSimOperator = codes.joined(separator: "-") // TODO: !
        return (networkName, telephonyNetworkSimCountry, telephonyNetworkSimOperator)
    }
    
    fileprivate func updateCellularInfo() {
        #if os(iOS)
        let netinfo = CTTelephonyNetworkInfo()
        var carrier: CTCarrier?
        var radioAccessTechnology: String?
        
        if #available(iOS 13.0, *) {
            if let providers = netinfo.serviceSubscriberCellularProviders,
               let dataIndetifier = netinfo.dataServiceIdentifier {
                carrier = providers[dataIndetifier]
                radioAccessTechnology = netinfo.serviceCurrentRadioAccessTechnology?[dataIndetifier]
            }
        } else {
            carrier = netinfo.subscriberCellularProvider
            if netinfo.responds(to: #selector(getter: CTTelephonyNetworkInfo.currentRadioAccessTechnology)) {
                radioAccessTechnology = netinfo.currentRadioAccessTechnology
            }
        }
        //Get carrier name
        if let carrier = carrier {
            let network = getNetworkInfo(for: carrier)
            networkName = network.networkName
            telephonyNetworkSimCountry = network.telephonyNetworkSimCountry
            telephonyNetworkSimOperator = network.telephonyNetworkSimOperator
        }
        //Get access technology
        if let radioAccessTechnology = radioAccessTechnology {
            cellularCode = cellularCodeForCTValue(radioAccessTechnology)
            cellularCodeDescription = cellularCodeDescriptionForCTValue(radioAccessTechnology)
        }
        #endif
    }
    
    ///
    fileprivate func getWiFiParameters() -> (ssid: String, bssid: String)? {
        //if #available(iOS 9, *) {

            // http://stackoverflow.com/questions/32970711/is-it-possible-to-get-wifi-signal-strength-in-ios-9

        //} else { // pre iOS 9 way
        #if os(OSX)
        // TODO
        #else
        #if os(iOS)
        if let interfaces = CNCopySupportedInterfaces() as? [CFString] {
            for interface in interfaces {
                if let interfaceData = CNCopyCurrentNetworkInfo(interface) as? [CFString: Any],
                let currentSSID = interfaceData[kCNNetworkInfoKeySSID] as? String,
                let currentBSSID = interfaceData[kCNNetworkInfoKeyBSSID] as? String {
                    return (ssid: currentSSID, bssid: RMBTReformatHexIdentifier(currentBSSID))
                }
            }
        }
        #endif
        #endif
        //}

        return nil
    }

    ///
    fileprivate func cellularCodeForCTValue(_ value: String?) -> Int? {
        guard let value = value else { return nil }

        #if os(iOS)
            //??????
        return cellularCodeTable[value]
        #else
        return nil
        #endif
    }

    ///
    fileprivate func cellularCodeDescriptionForCTValue(_ value: String!) -> String? {
        if value == nil {
            return nil
        }

        #if os(iOS)
        return cellularCodeDescriptionTable[value] ?? nil
        #else
        return nil
        #endif
    }

    ///
    open func isEqualToConnectivity(_ otherConn: RMBTConnectivity?) -> Bool {
        if let other = otherConn {
            if other === self {
                return true
            }

            // cannot compare two optional strings with ==, because one or both could be nil
            if let oNetworkName = other.networkName, let sNetworkName = self.networkName {
                return other.networkTypeDescription == self.networkTypeDescription && oNetworkName == sNetworkName
            }
        }

        return false
    }

    ///
    open func getInterfaceInfo() -> RMBTConnectivityInterfaceInfo {
        return RMBTTrafficCounter.getInterfaceInfo(networkType.rawValue)
    }

}
