//
//  RMBTHelpers.swift
//  RMBT
//
//  Created by Benjamin Pucher on 02.04.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

/// taken from http://stackoverflow.com/questions/24051904/how-do-you-add-a-dictionary-of-items-into-another-dictionary
/// this should be in the swift standard library!
// func +=<K, V>(inout left: Dictionary<K, V>, right: Dictionary<K, V>) -> Dictionary<K, V> {
//    for (k, v) in right {
//        left.updateValue(v, forKey: k)
//    }
//
//    return left
// }
public func +=<K, V>(inout left: [K: V], right: [K: V]) {
    for (k, v) in right {
        left[k] = v
    }
}

/// Returns a string containing git commit, branch and commit count from Info.plist fields written by the build script
public func RMBTBuildInfoString() -> String {
    let info = NSBundle.mainBundle().infoDictionary!

    let gitBranch       = info["GitBranch"] as? String ?? "none"
    let gitCommitCount  = info["GitCommitCount"] as? String ?? "-1"
    let gitCommit       = info["GitCommit"] as? String ?? "none"

    return "\(gitBranch)-\(gitCommitCount)-\(gitCommit)"
    // return String(format: "%@-%@-%@", info["GitBranch"], info["GitCommitCount"], info["GitCommit"])
}

///
public func RMBTBuildDateString() -> String {
    let info = NSBundle.mainBundle().infoDictionary!

    return info["BuildDate"] as! String
}

public func RMBTVersionString() -> String {
    let info = NSBundle.mainBundle().infoDictionary!

    return "\(info["CFBundleShortVersionString"] as! String) (\(info["CFBundleVersion"] as! String))"
}

///
public func RMBTPreferredLanguage() -> String? {
    let preferredLanguages = NSLocale.preferredLanguages()

    // logger.debug("\(preferredLanguages)")

    if preferredLanguages.count < 1 {
        return nil
    }

    let sep = preferredLanguages[0].componentsSeparatedByString("-")

    var lang = sep[0] // becuase sometimes (ios9?) there's "en-US" instead of en

    if sep.count > 1 && sep[1] == "Latn" { // add Latn if available, but don't add other country codes
        lang += "-Latn"
    }

    return lang
}

/// Replaces $lang in template with the current locale.
/// Fallback to english for non-translated languages is done on the server side.
public func RMBTLocalizeURLString(urlString: NSString) -> String {
    let r = urlString.rangeOfString("$lang")

    if r.location == NSNotFound {
        return urlString as String // return same string if no $lang was found
    }

    let lang = RMBTPreferredLanguage() ?? "en"

    let replacedURL = urlString.stringByReplacingOccurrencesOfString("$lang", withString: lang)

    // logger.debug("replaced $lang in string, output: \(replacedURL)")

    return replacedURL
}

/// Returns bundle name from Info.plist (e.g. SPECURE NetTest)
public func RMBTAppTitle() -> String {
    let info = NSBundle.mainBundle().infoDictionary!

    return info["CFBundleDisplayName"] as! String
}

public func RMBTAppCustomerName() -> String {
    let info = NSBundle.mainBundle().infoDictionary!

    return info["CFCustomerName"] as! String
}

///
public func RMBTValueOrNull(value: AnyObject!) -> AnyObject {
//    return value ?? NSNUll()
    return (value != nil) ? value : NSNull()
}

///
public func RMBTValueOrString(value: AnyObject!, _ result: String) -> AnyObject {
//    return value ?? result
    return (value != nil) ? value : result
}

///
public func RMBTCurrentNanos() -> UInt64 {
    var info = mach_timebase_info(numer: 0, denom: 0)
    mach_timebase_info(&info) // TODO: dispatch_once?

    // static dispatch_once_t onceToken;
    // static mach_timebase_info_data_t info;
    // dispatch_once(&onceToken, ^{
    //    mach_timebase_info(&info);
    // });

    var now = mach_absolute_time()
    now *= UInt64(info.numer)
    now /= UInt64(info.denom)

    return now
}

///
public func RMBTMillisecondsStringWithNanos(nanos: UInt64) -> String {
    let ms = NSNumber(double: Double(nanos) * 1.0e-6)
    return "\(RMBTFormatNumber(ms)) ms"
}

///
public func RMBTSecondsStringWithNanos(nanos: UInt64) -> String {
    return NSString(format: "%f s", Double(nanos) * 1.0e-9) as String
}

///
public func RMBTTimestampWithNSDate(date: NSDate) -> NSNumber {
    return NSNumber(unsignedLongLong: UInt64(date.timeIntervalSince1970) * 1000)
}

/// Format a number to two significant digits. See https://trac.rtr.at/iosrtrnetztest/ticket/17
public func RMBTFormatNumber(number: NSNumber) -> String {
    let formatter = NSNumberFormatter()

    // TODO: dispatch_once
    formatter.decimalSeparator = "."
    formatter.usesSignificantDigits = true
    formatter.minimumSignificantDigits = 2
    formatter.maximumSignificantDigits = 2
    //

    return formatter.stringFromNumber(number)!
}

/// Normalize hexadecimal identifier, i.e. 0:1:c -> 00:01:0c
public func RMBTReformatHexIdentifier(identifier: String!) -> String! { // !
    if identifier == nil {
        return nil
    }

    var tmp = [String]()

    for c in identifier.componentsSeparatedByString(":") {
        if c.characters.count == 0 {
            tmp.append("00")
        } else if c.characters.count == 1 {
            tmp.append("0\(c)")
        } else {
            tmp.append(c)
        }
    }

    return tmp.joinWithSeparator(":")
}
