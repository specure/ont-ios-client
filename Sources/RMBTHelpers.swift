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

/// taken from http://stackoverflow.com/questions/24051904/how-do-you-add-a-dictionary-of-items-into-another-dictionary
/// this should be in the swift standard library!
// func +=<K, V>(inout left: Dictionary<K, V>, right: Dictionary<K, V>) -> Dictionary<K, V> {
//    for (k, v) in right {
//        left.updateValue(v, forKey: k)
//    }
//
//    return left
// }
func +=<K, V>(left: inout [K: V], right: [K: V]) {
    for (k, v) in right {
        left[k] = v
    }
}

///


/// Returns a string containing git commit, branch and commit count from Info.plist fields written by the build script
public func RMBTBuildInfoString() -> String {
    let info = Bundle.main.infoDictionary!

    let gitBranch       = info["GitBranch"] as? String ?? "none"
    let gitCommitCount  = info["GitCommitCount"] as? String ?? "-1"
    let gitCommit       = info["GitCommit"] as? String ?? "none"

    return "\(gitBranch)-\(gitCommitCount)-\(gitCommit)"
    // return String(format: "%@-%@-%@", info["GitBranch"], info["GitCommitCount"], info["GitCommit"])
}

///
public func RMBTBuildDateString() -> String {
    let info = Bundle.main.infoDictionary!

    return info["BuildDate"] as! String
}

///
public func RMBTVersionString() -> String {
    let info = Bundle.main.infoDictionary!

    return "\(info["CFBundleShortVersionString"] as! String) (\(info["CFBundleVersion"] as! String))"
}

/////
// 
public func RMBTPreferredLanguage() -> String? {
    let preferredLanguages = Locale.preferredLanguages

    logger.debug("\(preferredLanguages)")

    if preferredLanguages.count < 1 {
        return nil
    }

    let sep = preferredLanguages[0].components(separatedBy: "-")
    
    var lang = sep[0] // becuase sometimes (ios9?) there's "en-US" instead of en

    if sep.count > 1 && sep[1] == "Latn" { // add Latn if available, but don't add other country codes
        lang += "-Latn"
    }
    
    // experiment need to test
    // lang = PREFFERED_LANGUAGE

    return lang
}

/// Replaces $lang in template with the current locale.
/// Fallback to english for non-translated languages is done on the server side.
public func RMBTLocalizeURLString(_ urlString: NSString) -> String {
    let r = urlString.range(of: LANGUAGE_PREFIX)

    if r.location == NSNotFound {
        return urlString as String // return same string if no $lang was found
    }

    let lang = PREFFERED_LANGUAGE

    let replacedURL = urlString.replacingOccurrences(of: LANGUAGE_PREFIX, with: lang)

    // logger.debug("replaced $lang in string, output: \(replacedURL)")

    return replacedURL
}

/// Returns bundle name from Info.plist (e.g. SPECURE NetTest)
public func RMBTAppTitle() -> String {
    let info = Bundle.main.infoDictionary!

    return info["CFBundleDisplayName"] as! String
}

///
public func RMBTAppCustomerName() -> String {
    let info = Bundle.main.infoDictionary!

    return info["CFCustomerName"] as! String
}

///
public func RMBTValueOrNull(_ value: AnyObject!) -> Any {
//    return value ?? NSNUll()
    return (value != nil) ? value : NSNull()
}

///
public func RMBTValueOrString(_ value: AnyObject!, _ result: String) -> Any {
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
public func RMBTMillisecondsStringWithNanos(_ nanos: UInt64) -> String {
    return RMBTMillisecondsString(nanos) + " ms"
}

///
public func RMBTMillisecondsString(_ nanos: UInt64) -> String {
    let ms = NSNumber(value: Double(nanos) * 1.0e-6 as Double)
    return "\(RMBTFormatNumber(ms))"
}

///
public func RMBTSecondsStringWithNanos(_ nanos: UInt64) -> String {
    return NSString(format: "%f s", Double(nanos) * 1.0e-9) as String
}

///
public func RMBTTimestampWithNSDate(_ date: Date) -> NSNumber {
    return NSNumber(value: UInt64(date.timeIntervalSince1970) * 1000 as UInt64)
}

///
public func NKOMTimestampWithNSDate(_ date: Date) -> NSNumber {
    return NSNumber(value: UInt64(date.timeIntervalSince1970) as UInt64)
}

/// Format a number to two significant digits. See https://trac.rtr.at/iosrtrnetztest/ticket/17
public func RMBTFormatNumber(_ number: NSNumber) -> String {
    let formatter = NumberFormatter()
    
    var signif = 2

    if number.doubleValue < 1 {
        signif = 1
    }

    // TODO: dispatch_once
    formatter.decimalSeparator = "."
    formatter.usesSignificantDigits = true
    formatter.minimumSignificantDigits = signif
    formatter.maximumSignificantDigits = signif
    //
    
    

    return formatter.string(from: number)!
}

/// Normalize hexadecimal identifier, i.e. 0:1:c -> 00:01:0c
public func RMBTReformatHexIdentifier(_ identifier: String!) -> String! { // !
    if identifier == nil {
        return nil
    }

    var tmp = [String]()

    for c in identifier.components(separatedBy: ":") {
        if c.characters.count == 0 {
            tmp.append("00")
        } else if c.characters.count == 1 {
            tmp.append("0\(c)")
        } else {
            tmp.append(c)
        }
    }

    return tmp.joined(separator: ":")
}
