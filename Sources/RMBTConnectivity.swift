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
open class RMBTConnectivity {

    ///
    open let networkType: RMBTNetworkType

    ///
    open let timestamp: Date

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
            logger.warning("Invalid network type \(self.networkType)")
            return NSLocalizedString("intro.network.connection.name-unknown", tableName: nil, bundle: Bundle.main, value: "Unknown", comment: "network type description unknown")
        }
    }

    ///
    open var networkName: String!

    ///
    open var bssid: String!

    ///
    var cellularCode: NSNumber!

    ///
    var cellularCodeDescription: String!

    ///
    open var telephonyNetworkSimOperator: String!

    ///
    open var telephonyNetworkSimCountry: String!

    #if os(iOS)

    ///
    fileprivate let cellularCodeTable = [
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

    ///
    fileprivate let cellularCodeDescriptionTable = [
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
        CTRadioAccessTechnologyeHRPD:           "HRPD (2G)"
    ]

    #endif

    ///
    public init(networkType: RMBTNetworkType) {
        self.networkType = networkType
        timestamp = Date()

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
            #if os(iOS)
            // Get carrier name
            let netinfo = CTTelephonyNetworkInfo()
            if let carrier = netinfo.subscriberCellularProvider {
                networkName = carrier.carrierName
                telephonyNetworkSimCountry = carrier.isoCountryCode
                telephonyNetworkSimOperator = "\(carrier.mobileCountryCode!)-\(carrier.mobileNetworkCode!)" // TODO: !
            }

            if netinfo.responds(to: #selector(getter: CTTelephonyNetworkInfo.currentRadioAccessTechnology)) {
                // iOS 7
                cellularCode = cellularCodeForCTValue(netinfo.currentRadioAccessTechnology)
                cellularCodeDescription = cellularCodeDescriptionForCTValue(netinfo.currentRadioAccessTechnology)
            }
            #else
            break
            #endif
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

    ///
    fileprivate func getWiFiParameters() -> (ssid: String, bssid: String)? {
        //if #available(iOS 9, *) {

            // http://stackoverflow.com/questions/32970711/is-it-possible-to-get-wifi-signal-strength-in-ios-9

        //} else { // pre iOS 9 way
        #if os(OSX)
        // TODO
        #else
            if let interfaces = CNCopySupportedInterfaces() {
                for i in 0..<CFArrayGetCount(interfaces) {
                    let interfaceName: UnsafeRawPointer = CFArrayGetValueAtIndex(interfaces, i)
                    let rec = unsafeBitCast(interfaceName, to: AnyObject.self)
                    if let unsafeInterfaceData = CNCopyCurrentNetworkInfo("\(rec)" as CFString) {
                        let interfaceData = unsafeInterfaceData as! [AnyHashable: Any]

                        if let currentSSID = interfaceData[kCNNetworkInfoKeySSID as AnyHashable] as? String,
                            let currentBSSID = interfaceData[kCNNetworkInfoKeyBSSID as AnyHashable] as? String {
                                return (ssid: currentSSID, bssid: RMBTReformatHexIdentifier(currentBSSID))
                        }
                    }
                }
            }
            #endif
        //}

        return nil
    }

    ///
    fileprivate func cellularCodeForCTValue(_ value: String!) -> NSNumber? {
        if value == nil {
            return nil
        }

        #if os(iOS)
            //??????
        return (cellularCodeTable[value] as AnyObject) as? NSNumber
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
