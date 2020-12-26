//
//  UserDefaults+Extension.swift
//  RMBT
//
//  Created by Tomas Baculák on 19/07/2017.
//  Copyright © 2017 SPECURE GmbH. All rights reserved.
//

#if os(iOS)
import UIKit
#endif

import Foundation

///
let TOS_VERSION_KEY = "tos_version"

extension UserDefaults {
    
    /// Generic function
    open class func storeDataFor(key: String, obj: Any) {
    
        UserDefaults.standard.set(obj, forKey: key)
        UserDefaults.standard.synchronize()
    }
    
    ///
    open class func getDataFor(key: String) -> Any? {
    
        guard let result = UserDefaults.standard.object(forKey: key) else {
            return nil
        }
        
        return result
    }
    
    ///
    open class func storeTOSVersion(lastAcceptedVersion: Int) {
        storeDataFor(key: TOS_VERSION_KEY, obj: lastAcceptedVersion)
    }
    
    ///
    open class func getTOSVersion() -> Int {
        return UserDefaults.standard.integer(forKey: TOS_VERSION_KEY)
    }
    
    open class func clearStoredUUID(uuidKey: String?) {
        if let uuidKey = uuidKey {
            UserDefaults.standard.removeObject(forKey: uuidKey)
            UserDefaults.standard.synchronize()
        }
    }
    ///
    open class func storeNewUUID(uuidKey: String, uuid: String) {
        if RMBTSettings.sharedSettings.isClientPersistent {
            storeDataFor(key: uuidKey, obj: uuid)
            Log.logger.debug("UUID: uuid is now: \(uuid) for key '\(uuidKey)'")
        }
    }
    
    ///
    open class func checkStoredUUID(uuidKey: String?) -> String? {
        
        //NKOM reconciliation can be deleted after another distant future release

        var reconHost: String?
        reconHost = uuidKey?.replacingOccurrences(of: "uuid_", with: "") //"netcouch.specure.com"
        let reconKey = "uuid_\(String(describing: reconHost))"
        if let reconUUID = UserDefaults.standard.object(forKey: reconKey) {
            Log.logger.debug("UUID: Found old uuid \"\(reconUUID)\" in user defaults for key '\(reconKey)'")
            return reconUUID as? String
        }
        ///////////////////////////////////////////////////////////////////////////
    
        let uuid:String?
        // load uuid
        if let key = uuidKey {
            uuid = UserDefaults.standard.object(forKey: key) as? String
            
            Log.logger.debugExec({
                if uuid != nil {
                    Log.logger.debug("UUID: Found uuid \"\(String(describing: uuid))\" in user defaults for key '\(key)'")
                } else {
                    Log.logger.debug("UUID: Uuid was not found in user defaults for key '\(key)'")
                }
            })
            
            if uuid != nil { return uuid! }
        }
        return nil
    }
    
    ///
    open class func storeRequestUserAgent() {
    
        guard let info = Bundle.main.infoDictionary,
            let bundleName = (info["CFBundleName"] as? String)?.replacingOccurrences(of: " ", with: ""),
            let bundleVersion = info["CFBundleShortVersionString"] as? String
        else { return }
        
        let iosVersion = UIDevice.current.systemVersion
        
        let lang = PREFFERED_LANGUAGE
        var locale = Locale.canonicalLanguageIdentifier(from: lang)
        
        if let countryCode = (Locale.current as NSLocale).object(forKey: NSLocale.Key.countryCode) as? String {
            locale += "-\(countryCode)"
        }
        
        // set global user agent
        let specureUserAgent = "SpecureNetTest/2.0 (iOS; \(locale); \(iosVersion)) \(bundleName)/\(bundleVersion)"
        UserDefaults.standard.set(specureUserAgent, forKey: "UserAgent")
        UserDefaults.standard.synchronize()
        
        Log.logger.info("USER AGENT: \(specureUserAgent)")
    }
    
    ///
    open class func getRequestUserAgent() -> String? {
        guard let user = UserDefaults.standard.string(forKey: "UserAgent") else {
            return nil
        }
        
        return user
    }

    ///
    open class func checkFirstLaunch() -> Bool {
        
        if !UserDefaults.standard.bool(forKey: "was_launched_once") {
            Log.logger.info("FIRST LAUNCH OF APP")
            
            UserDefaults.standard.set(true, forKey: "was_launched_once")
            
            firstLaunch(UserDefaults.standard)
            UserDefaults.standard.synchronize()
            
            return true
        }
        return true
    }
    
    ///
    private class func firstLaunch(_ userDefaults: UserDefaults) {
        if TEST_USE_PERSONAL_DATA_FUZZING {
            RMBTSettings.sharedSettings.publishPublicData = true
            Log.logger.debug("setting publishPublicData to true")
        }
    }

}
