//
//  UserDefaults+Extension.swift
//  RMBT
//
//  Created by Tomas Baculák on 19/07/2017.
//  Copyright © 2017 SPECURE GmbH. All rights reserved.
//

import Foundation
import UIKit

///
let TOS_VERSION_KEY = "tos_version"

let UserStandard = UserDefaults.standard

extension UserDefaults {
    
    /// Generic function
    open class func storeDataFor(key:String, obj:Any) {
    
        UserStandard.set(obj, forKey: key)
        UserStandard.synchronize()
    }
    
    ///
    open class func getDataFor(key:String) -> Any? {
    
        guard let result = UserStandard.object(forKey: key) else {
            return nil
        }
        
        return result
    }
    
    ///
    open class func storeTOSVersion(lastAcceptedVersion:Int) {
        storeDataFor(key: TOS_VERSION_KEY, obj: lastAcceptedVersion)
    }
    
    ///
    open class func getTOSVersion() -> Int {
        return UserStandard.integer(forKey: TOS_VERSION_KEY)
    }
    
    ///
    open class func storeNewUUID(uuidKey:String, uuid:String) {
    
        storeDataFor(key: uuidKey, obj: uuid)
        logger.debug("UUID: uuid is now: \(uuid) for key '\(uuidKey)'")
    }
    
    ///
    open class func checkStoredUUID(uuidKey:String?) -> String? {
        
        //NKOM reconciliation can be deleted after another distant future release

        var reconHost:String?
        reconHost = uuidKey?.replacingOccurrences(of: "uuid_", with: "") //"netcouch.specure.com"
        let reconKey = "uuid_\(String(describing: reconHost))"
        if let reconUUID = UserStandard.object(forKey: reconKey) {
            logger.debug("UUID: Found old uuid \"\(reconUUID)\" in user defaults for key '\(reconKey)'")
            return reconUUID as? String
        }
        ///////////////////////////////////////////////////////////////////////////
    
        let uuid:String?
        // load uuid
        if let key = uuidKey {
            uuid = UserStandard.object(forKey: key) as? String
            
            logger.debugExec({
                if uuid != nil {
                    logger.debug("UUID: Found uuid \"\(String(describing: uuid))\" in user defaults for key '\(key)'")
                } else {
                    logger.debug("UUID: Uuid was not found in user defaults for key '\(key)'")
                }
            })
            
            if uuid != nil { return uuid! }
        }
        return nil
    }
    
    ///
    open class func storeRequestUserAgent() {
    
        let info = Bundle.main.infoDictionary!
        
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
        UserStandard.register(defaults: ["UserAgent": specureUserAgent])
        UserStandard.synchronize()
        
        logger.info("USER AGENT: \(specureUserAgent)")
    }
    
    ///
    open class func getRequestUserAgent() -> String? {
        guard let user = UserStandard.string(forKey: "UserAgent") else {
            return nil
        }
        
        return user
    }

    ///
    open class func checkFirstLaunch() {
        
        if !UserStandard.bool(forKey: "was_launched_once") {
            logger.info("FIRST LAUNCH OF APP")
            
            UserStandard.set(true, forKey: "was_launched_once")
            
            firstLaunch(UserStandard)
            UserStandard.synchronize()
        }
    }
    
    ///
    private class func firstLaunch(_ userDefaults: UserDefaults) {
        if TEST_USE_PERSONAL_DATA_FUZZING {
            RMBTSettings.sharedSettings.publishPublicData = true
            logger.debug("setting publishPublicData to true")
        }
    }

}
