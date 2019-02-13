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

///
open class RMBTSettings: NSObject {

    public enum NerdModeQosMode: Int {
        case manually
        case newNetwork
        case always
    }
    
    ///
    public static let sharedSettings = RMBTSettings()

// MARK: Temporary app state (global variables)

    ///
    @objc open dynamic var mapOptionsSelection: RMBTMapOptionsSelection

// MARK: Persisted app state

    ///
    @objc open dynamic var testCounter: UInt = 0

    ///
    @objc open dynamic var previousTestStatus: String?

// MARK: User configurable properties

    ///
    @objc open dynamic var publishPublicData = false // only for akos
    
    @objc open dynamic var submitZeroTesting = true

    /// anonymous mode
    @objc open dynamic var anonymousModeEnabled = false

// MARK: Nerd mode

    ///
    @objc open dynamic var nerdModeEnabled = false

    ///
    @objc open dynamic var nerdModeForceIPv4 = false

    ///
    @objc open dynamic var nerdModeForceIPv6 = false
    
    @objc open dynamic var isDarkMode = false

    ///
    @objc open dynamic var nerdModeQosEnabled = NerdModeQosMode.newNetwork.rawValue // Enable QoS

// MARK: Debug properties

    ///
    @objc open dynamic var debugUnlocked = false

    // loop mode

    ///
    @objc open dynamic var debugLoopMode = false

    ///
    @objc open dynamic var debugLoopModeMaxTests: UInt = 0

    ///
    @objc open dynamic var debugLoopModeMinDelay: UInt = 0
    
    @objc open dynamic var debugLoopModeSkipQOS: Bool = false
    
    @objc open dynamic var debugLoopModeDistance: UInt = 0
    
    @objc open dynamic var debugLoopModeIsStartImmedatelly: Bool = true

    // control server

    ///
    @objc open dynamic var debugControlServerCustomizationEnabled = false

    ///
    @objc open dynamic var debugControlServerHostname: String?

    ///
    @objc open dynamic var debugControlServerPort: UInt = 0

    ///
    @objc open dynamic var debugControlServerUseSSL = false

    // map server

    ///
    @objc open dynamic var debugMapServerCustomizationEnabled = false

    ///
    @objc open dynamic var debugMapServerHostname: String?

    ///
    @objc open dynamic var debugMapServerPort: UInt = 0

    ///
    @objc open dynamic var debugMapServerUseSSL = false

    // logging

    ///
    @objc open dynamic var debugLoggingEnabled = false
    
    @objc open dynamic var previousNetworkName: String?
    @objc open dynamic var isAdsRemoved: Bool = false
    
    @objc open dynamic var lastSurveyTimestamp: Double = 0.0
    
    @objc open dynamic var isClientPersistent: Bool = true
    @objc open dynamic var isAnalyticsEnabled: Bool = true
    
    @objc open dynamic var countMeasurements: Int = 0
    @objc open dynamic var isDevModeEnabled: Bool = false

    ///
    private override init() {
        mapOptionsSelection = RMBTMapOptionsSelection()

        super.init()

        bindKeyPaths([
            "testCounter",
            "previousTestStatus",

            "debugUnlocked",
            "developerModeEnabled", // TODO: this should replace debug unlocked

            ///////////
            // USER SETTINGS

            // general
            "publishPublicData",
            "submitZeroTesting",

            // anonymous mode
            "anonymousModeEnabled",

            ///////////
            // NERD MODE

            // nerd mode
            "nerdModeEnabled",

            "nerdModeForceIPv4",
            "nerdModeForceIPv6",

            // nerd mode, advanced settings, qos
            "nerdModeQosEnabled",

            ///////////
            // DEVELOPER MODE

            // developer mode, advanced settings, loop mode
            "developerModeLoopMode",
            "developerModeLoopModeMaxTests",
            "developerModeLoopModeMinDelay",

            // control server

            "debugControlServerCustomizationEnabled",
            "debugControlServerHostname",
            "debugControlServerPort",
            "debugControlServerUseSSL",

            // map server

            "debugMapServerCustomizationEnabled",
            "debugMapServerHostname",
            "debugMapServerPort",
            "debugMapServerUseSSL",

            // logging

            "debugLoggingEnabled",
            "previousNetworkName",
            "isAdsRemoved",
            
            "lastSurveyTimestamp",
            
            //Loop mode
            "debugLoopMode",
            "debugLoopModeMaxTests",
            "debugLoopModeMinDelay",
            "debugLoopModeSkipQOS",
            "debugLoopModeDistance",
            "debugLoopModeIsStartImmedatelly",
            "isDarkMode",
            "isClientPersistent",
            "isAnalyticsEnabled",
            "countMeasurements",
            "isDevModeEnabled"
        ])
    }

    ///
    private func bindKeyPaths(_ keyPaths: [String]) {
        for keyPath in keyPaths {
            if let value = UserDefaults.getDataFor(key: keyPath) {
                setValue(value, forKey: keyPath)
            }

            // Start observing
//            addObserver(self, forKeyPath: keyPath, options: .new, context: nil)
            self.addObserver(self, forKeyPath: keyPath, options: [.new], context: nil)
        }
    }

    ///
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let newValue = change?[NSKeyValueChangeKey.newKey], let kp = keyPath {
            Log.logger.debugExec() {
                let oldValue = UserDefaults.getDataFor(key: kp)
                Log.logger.debug("Settings changed for keyPath '\(String(describing: keyPath))' from '\(String(describing: oldValue))' to '\(newValue)'")
            }

            UserDefaults.storeDataFor(key: kp, obj: newValue)
        }
    }
}
