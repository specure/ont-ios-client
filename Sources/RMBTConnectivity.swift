//
//  RMBTConnectivity.swift
//  RMBT
//
//  Created by Benjamin Pucher on 21.09.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation
import CoreTelephony
import SystemConfiguration.CaptiveNetwork
import NetworkExtension

///
public class RMBTConnectivity {

    ///
    public let networkType: RMBTNetworkType

    ///
    public let timestamp: NSDate

    ///
    public var networkTypeDescription: String {
        switch networkType {
        case .None:
            return NSLocalizedString("connectivity.not-connected", tableName: nil, bundle: NSBundle.mainBundle(), value: "Not connected", comment: "network type description not connected")
        case .WiFi:
            return NSLocalizedString("connectivity.wifi", tableName: nil, bundle: NSBundle.mainBundle(), value: "Wi-Fi", comment: "network type description wifi")
        case .Cellular:
            if cellularCodeDescription != nil {
                return cellularCodeDescription
            } else {
                return NSLocalizedString("connectivity.cellular", tableName: nil, bundle: NSBundle.mainBundle(), value: "Cellular", comment: "network type description cellular")
            }
        default:
            logger.warning("Invalid network type \(networkType)")
            return NSLocalizedString("intro.network.connection.name-unknown", tableName: nil, bundle: NSBundle.mainBundle(), value: "Unknown", comment: "network type description unknown")
        }
    }

    ///
    public var networkName: String!

    ///
    private var bssid: String!

    ///
    private var cellularCode: NSNumber!

    ///
    private var cellularCodeDescription: String!

    ///
    private var telephonyNetworkSimOperator: String!

    ///
    private var telephonyNetworkSimCountry: String!

    ///
    private let cellularCodeTable = [
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
    private let cellularCodeDescriptionTable = [
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

    ///
    public init(networkType: RMBTNetworkType) {
        self.networkType = networkType
        self.timestamp = NSDate()
        getNetworkDetails()
    }

// MARK: Internal

    ///
    public func getNetworkDetails() {
        networkName = nil
        bssid = nil
        cellularCode = nil
        cellularCodeDescription = nil

        switch networkType {
        case .Cellular:
            // Get carrier name
            let netinfo = CTTelephonyNetworkInfo()
            if let carrier = netinfo.subscriberCellularProvider {
                networkName = carrier.carrierName
                telephonyNetworkSimCountry = carrier.isoCountryCode
                telephonyNetworkSimOperator = "\(carrier.mobileCountryCode!)-\(carrier.mobileNetworkCode!)" // TODO: !
            }

            if netinfo.respondsToSelector(Selector("currentRadioAccessTechnology")) {
                // iOS 7
                cellularCode = cellularCodeForCTValue(netinfo.currentRadioAccessTechnology)
                cellularCodeDescription = cellularCodeDescriptionForCTValue(netinfo.currentRadioAccessTechnology)
            }
        case .WiFi:
            // If WLAN, then show SSID as network name. Fetching SSID does not work on the simulator.
            if let wifiParams = getWiFiParameters() {
                networkName = wifiParams.ssid
                bssid = wifiParams.bssid
            }

            break

        case .None:
            break
        default:
            assert(false, "Invalid network type \(networkType)")
        }
    }

    ///
    private func getWiFiParameters() -> (ssid: String, bssid: String)? {
        //if #available(iOS 9, *) {

            // http://stackoverflow.com/questions/32970711/is-it-possible-to-get-wifi-signal-strength-in-ios-9

        //} else { // pre iOS 9 way
            if let interfaces = CNCopySupportedInterfaces() {
                for i in 0..<CFArrayGetCount(interfaces) {
                    let interfaceName: UnsafePointer<Void> = CFArrayGetValueAtIndex(interfaces, i)
                    let rec = unsafeBitCast(interfaceName, AnyObject.self)
                    if let unsafeInterfaceData = CNCopyCurrentNetworkInfo("\(rec)") {
                        let interfaceData = unsafeInterfaceData as [NSObject: AnyObject]

                        if let currentSSID = interfaceData[kCNNetworkInfoKeySSID] as? String,
                            currentBSSID = interfaceData[kCNNetworkInfoKeyBSSID] as? String {
                                return (ssid: currentSSID, bssid: RMBTReformatHexIdentifier(currentBSSID))
                        }
                    }
                }
            }
        //}

        return nil
    }

    ///
    private func cellularCodeForCTValue(value: String!) -> NSNumber? {
        if value == nil {
            return nil
        }

        return cellularCodeTable[value] ?? nil
    }

    ///
    private func cellularCodeDescriptionForCTValue(value: String!) -> String? {
        if value == nil {
            return nil
        }

        return cellularCodeDescriptionTable[value] ?? nil
    }

    ///
    public func testResultDictionary() -> NSDictionary { // TODO: remove after control server rewrite
        var result = [String: AnyObject]()

        let code = networkType.rawValue
        if code > 0 {
            result["network_type"] = NSNumber(long: code)
        }

        if networkType == .WiFi {
            if networkName != nil {
                result["wifi_ssid"] = networkName
            }

            if bssid != nil {
                result["wifi_bssid"] = bssid
            }
        } else if networkType == .Cellular {
            if cellularCode != nil {
                result["network_type"] = cellularCode
            }

            result["telephony_network_sim_operator_name"]   = RMBTValueOrNull(networkName)
            result["telephony_network_sim_country"]         = RMBTValueOrNull(telephonyNetworkSimCountry)
            result["telephony_network_sim_operator"]        = RMBTValueOrNull(telephonyNetworkSimOperator)
        }

        return result
    }

    ///
    public func isEqualToConnectivity(otherConn: RMBTConnectivity?) -> Bool {
        if let other = otherConn {
            if other === self {
                return true
            }

            // cannot compare two optional strings with ==, because one or both could be nil
            if let oNetworkName = other.networkName, sNetworkName = self.networkName {
                return other.networkTypeDescription == self.networkTypeDescription && oNetworkName == sNetworkName
            }
        }

        return false
    }

    ///
    public func getInterfaceInfo() -> RMBTConnectivityInterfaceInfo {
        return RMBTTrafficCounter.getInterfaceInfo(networkType.rawValue)
    }

}
