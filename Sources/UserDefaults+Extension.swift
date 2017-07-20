//
//  UserDefaults+Extension.swift
//  RMBT
//
//  Created by Tomas Baculák on 19/07/2017.
//  Copyright © 2017 SPECURE GmbH. All rights reserved.
//

import Foundation

///
let TOS_VERSION_KEY = "tos_version"

extension UserDefaults {
    
    ///
    open class func storeTOSVersion(lastAcceptedVersion:Int) {
        UserDefaults.standard.set(lastAcceptedVersion, forKey: TOS_VERSION_KEY)
        UserDefaults.standard.synchronize()
    }
    
    ///
    open class func getTOSVersion() -> Int {
        return UserDefaults.standard.integer(forKey: TOS_VERSION_KEY)
    }
    
    ///
    open class func storeNewUUID(uuidKey:String, uuid:String) {
    
        UserDefaults.standard.set(uuid, forKey: uuidKey)
        UserDefaults.standard.synchronize()
        
        logger.debug("UUID: uuid is now: \(uuid) for key '\(uuidKey)'")
    }
    
    ///
    open class func checkStoredUUID(uuidKey:String?) -> String? {
    
        let uuid:String?
        // load uuid
        if let key = uuidKey {
            uuid = UserDefaults.standard.object(forKey: key) as? String
            
            logger.debugExec({
                if let theUuid = uuid {
                    logger.debug("UUID: Found uuid \"\(theUuid)\" in user defaults for key '\(key)'")
                } else {
                    logger.debug("UUID: Uuid was not found in user defaults for key '\(uuid)'")
                }
            })
            
            if (uuid != nil) { return uuid }
        }
        return nil
    }
    
    ///
    open class func storeRequestUserAgent() {
    
        let info = Bundle.main.infoDictionary!
        let userDefaults = UserDefaults.standard
        
        let bundleName = (info["CFBundleName"] as! String).replacingOccurrences(of: " ", with: "")
        let bundleVersion = info["CFBundleShortVersionString"] as! String
        
        let iosVersion = UIDevice.current.systemVersion
        
        let lang = PREFFERED_LANGUAGE
        var locale = Locale.canonicalLanguageIdentifier(from: lang)
        
        if let countryCode = (Locale.current as NSLocale).object(forKey: NSLocale.Key.countryCode) as? String {
            locale += "-\(countryCode)"
        }
        
        // set global user agent
        let specureUserAgent = "SpecureNetTest/2.0 (iOS; \(locale); \(iosVersion)) \(bundleName)/\(bundleVersion)"
        userDefaults.register(defaults: ["UserAgent": specureUserAgent])
        userDefaults.synchronize()
        
        logger.info("USER AGENT: \(specureUserAgent)")
    }
    
    ///
    open class func getRequestUserAgent() -> String? {
        guard let user = UserDefaults.standard.string(forKey: "UserAgent") else {
            return nil
        }
        
        return user
    }

    ///
    open class func checkFirstLaunch() {
        let userDefaults = UserDefaults.standard
        
        if !userDefaults.bool(forKey: "was_launched_once") {
            logger.info("FIRST LAUNCH OF APP")
            
            userDefaults.set(true, forKey: "was_launched_once")
            
            firstLaunch(userDefaults)
            
            userDefaults.synchronize()
        }
    }
    
    ///
    class func firstLaunch(_ userDefaults: UserDefaults) {
        if TEST_USE_PERSONAL_DATA_FUZZING {
            RMBTSettings.sharedSettings.publishPublicData = true
            logger.debug("setting publishPublicData to true")
        }
    }

}
