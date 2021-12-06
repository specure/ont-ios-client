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

/// these values are stored on the server side and kept here just for backup
let IOS_MODEL_DICTIONARY = [
// iPhone
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
    "iPhone8,4": "iPhone SE",
    "iPhone9,1": "iPhone 7 (CDMA)",
    "iPhone9,3": "iPhone 7 (GSM)",
    "iPhone9,2": "iPhone 7 Plus (CDMA)",
    "iPhone9,4": "iPhone 7 Plus (GSM)",
    "iPhone10,1": "iPhone 8",
    "iPhone10,2": "iPhone 8 Plus",
    "iPhone10,3": "iPhone X Global",
    "iPhone10,4": "iPhone 8",
    "iPhone10,5": "iPhone 8 Plus",
    "iPhone10,6": "iPhone X GSM",
    "iPhone11,2": "iPhone XS",
    "iPhone11,4": "iPhone XS Max",
    "iPhone11,6": "iPhone XS Max Global",
    "iPhone11,8": "iPhone XR",
    "iPhone12,1": "iPhone 11",
    "iPhone12,3": "iPhone 11 Pro",
    "iPhone12,5": "iPhone 11 Pro Max",
    "iPhone12,8": "iPhone SE 2nd Gen",
    "iPhone13,1": "iPhone 12 Mini",
    "iPhone13,2": "iPhone 12",
    "iPhone13,3": "iPhone 12 Pro",
    "iPhone13,4": "iPhone 12 Pro Max",
// iPod
    "iPod1,1": "iPod Touch 1G",
    "iPod2,1": "iPod Touch 2G",
    "iPod3,1": "iPod Touch 3G",
    "iPod4,1": "iPod Touch 4G",
    "iPod5,1": "iPod Touch 5G",
    "iPod7,1": "iPod Touch 6",
    "iPod9,1": "7th Gen iPod",
// iPad
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
    "iPad5,1": "iPad Mini 4",
    "iPad5,2": "iPad Mini 4",
    "iPad5,3": "iPad Air 2 (WiFi)",
    "iPad5,4": "iPad Air 2 (GSM)",
    "iPad6,3": "iPad Pro",
    "iPad6,4": "iPad Pro",
    "iPad6,7": "iPad Pro",
    "iPad6,8": "iPad Pro",
    "iPad6,11": "iPad (2017)",
    "iPad6,12": "iPad (2017)",
    "iPad7,1": "iPad Pro 2nd Gen (WiFi)",
    "iPad7,2": "iPad Pro 2nd Gen (WiFi+Cellular)",
    "iPad7,3": "iPad Pro 10.5-inch",
    "iPad7,4": "iPad Pro 10.5-inch",
    "iPad7,5": "iPad 6th Gen (WiFi)",
    "iPad7,6": "iPad 6th Gen (WiFi+Cellular)",
    "iPad7,11": "iPad 7th Gen 10.2-inch (WiFi)",
    "iPad7,12": "iPad 7th Gen 10.2-inch (WiFi+Cellular)",
    "iPad8,1": "iPad Pro 11 inch 3rd Gen (WiFi)",
    "iPad8,2": "iPad Pro 11 inch 3rd Gen (1TB, WiFi)",
    "iPad8,3": "iPad Pro 11 inch 3rd Gen (WiFi+Cellular)",
    "iPad8,4": "iPad Pro 11 inch 3rd Gen (1TB, WiFi+Cellular)",
    "iPad8,5": "iPad Pro 12.9 inch 3rd Gen (WiFi)",
    "iPad8,6": "iPad Pro 12.9 inch 3rd Gen (1TB, WiFi)",
    "iPad8,7": "iPad Pro 12.9 inch 3rd Gen (WiFi+Cellular)",
    "iPad8,8": "iPad Pro 12.9 inch 3rd Gen (1TB, WiFi+Cellular)",
    "iPad8,9": "iPad Pro 11 inch 4th Gen (WiFi)",
    "iPad8,10": "iPad Pro 11 inch 4th Gen (WiFi+Cellular)",
    "iPad8,11": "iPad Pro 12.9 inch 4th Gen (WiFi)",
    "iPad8,12": "iPad Pro 12.9 inch 4th Gen (WiFi+Cellular)",
    "iPad11,1": "iPad mini 5th Gen (WiFi)",
    "iPad11,2": "iPad mini 5th Gen",
    "iPad11,3": "iPad Air 3rd Gen (WiFi)",
    "iPad11,4": "iPad Air 3rd Gen",
    "iPad11,6": "iPad 8th Gen (WiFi)",
    "iPad11,7": "iPad 8th Gen (WiFi+Cellular)",
    "iPad13,1": "iPad air 4th Gen (WiFi)",
    "iPad13,2": "iPad air 4th Gen (WiFi+Celular)",
// Apple TV
    "AppleTV1,1": "Apple TV",
    "AppleTV2,1": "Apple TV 2G",
    "AppleTV3,1": "Apple TV 3G",
    "AppleTV3,2": "Apple TV 3G",
    "AppleTV5,3": "Apple TV 4G",
// Simulator
    "i386":            "iOS Simulator",
    "x86_64":          "iOS Simulator",
    "Emulator x86_64": "iOS Simulator",

    // TODO: add appletv
]

///
open class UIDeviceHardware {

    ///
    open class func platform() -> String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)

        var machine = [CChar](repeating: 0, count: Int(size))
        sysctlbyname("hw.machine", &machine, &size, nil, 0)

        return String(cString: machine)
    }

    ///
    open class func platformString() -> String {
        return getDeviceNameFromPlatform(platform())
    }

    ///
    open class func getDeviceNameFromPlatform(_ platform: String) -> String {
        return IOS_MODEL_DICTIONARY[platform] ?? platform
    }

}
