//
//  UIDeviceHardware.swift
//  RMBT
//
//  Created by Benjamin Pucher on 27.03.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

/// these values are stored on the server side and kept here just for backup
let IOS_MODEL_DICTIONARY = [
    "iPhone1,1": "iPhone 1G",
    "iPhone1,2": "iPhone 3G",
    "iPhone2,1": "iPhone 3GS",
    "iPhone3,1": "iPhone 4 (GSM)",
    "iPhone3,2": "iPhone 4 Rev A",
    "iPhone3,3": "iPhone 4 (CDMA)",
    "iPhone4,1": "iPhone 4S",
    "iPhone5,1": "iPhone 5 (GSM)",
    "iPhone5,2": "iPhone 5 (GSM+CDMA)",
    "iPhone5,3": "iPhone 5c (GSM)",
    "iPhone5,4": "iPhone 5c (GSM+CDMA)",
    "iPhone6,1": "iPhone 5s (GSM)",
    "iPhone6,2": "iPhone 5s (GSM+CDMA)",
    "iPhone7,1": "iPhone 6 Plus",
    "iPhone7,2": "iPhone 6",
    "iPhone8,1": "iPhone 6s",
    "iPhone8,2": "iPhone 6s Plus",

    "iPod1,1": "iPod Touch 1G",
    "iPod2,1": "iPod Touch 2G",
    "iPod3,1": "iPod Touch 3G",
    "iPod4,1": "iPod Touch 4G",
    "iPod5,1": "iPod Touch 5G",

    "iPad1,1": "iPad",
    "iPad2,1": "iPad 2 (WiFi)",
    "iPad2,2": "iPad 2 (GSM)",
    "iPad2,3": "iPad 2 (CDMA)",
    "iPad2,4": "iPad 2 (WiFi)",
    "iPad2,5": "iPad Mini (WiFi)",
    "iPad2,6": "iPad Mini (GSM)",
    "iPad2,7": "iPad Mini (GSM+CDMA)",
    "iPad3,1": "iPad 3 (WiFi)",
    "iPad3,2": "iPad 3 (GSM+CDMA)",
    "iPad3,3": "iPad 3 (GSM)",
    "iPad3,4": "iPad 4 (WiFi)",
    "iPad3,5": "iPad 4 (GSM)",
    "iPad3,6": "iPad 4 (GSM+CDMA)",
    "iPad4,1": "iPad Air (WiFi)",
    "iPad4,2": "iPad Air (GSM)",
    "iPad4,3": "iPad Air (LTE)",
    "iPad4,4": "iPad Mini 2 (WiFi)",
    "iPad4,5": "iPad Mini 2 (GSM)",
    "iPad4,6": "iPad Mini 2 (LTE)",
    "iPad4,7": "iPad Mini 3 (WiFi)",
    "iPad4,8": "iPad Mini 3 (GSM)",
    "iPad4,9": "iPad Mini 3 (LTE)",
    "iPad5,3": "iPad Air 2 (WiFi)",
    "iPad5,4": "iPad Air 2 (GSM)",

    "i386":            "iOS Simulator",
    "x86_64":          "iOS Simulator",
    "Emulator x86_64": "iOS Simulator",

    // TODO: add appletv
]

///
public class UIDeviceHardware {

    ///
    public class func platform() -> String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)

        var machine = [CChar](count: Int(size), repeatedValue: 0)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)

        return String.fromCString(machine)!
    }

    ///
    public class func platformString() -> String {
        return getDeviceNameFromPlatform(platform())
    }

    ///
    public class func getDeviceNameFromPlatform(platform: String) -> String {
        return IOS_MODEL_DICTIONARY[platform] ?? platform
    }

}
