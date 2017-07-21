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

    ///
    open static let sharedSettings = RMBTSettings()

// MARK: Temporary app state (global variables)

    ///
    open dynamic var mapOptionsSelection: RMBTMapOptionsSelection

// MARK: Persisted app state

    ///
    open dynamic var testCounter: UInt = 0

    ///
    open dynamic var previousTestStatus: String?

// MARK: User configurable properties

    ///
    open dynamic var publishPublicData = false // only for akos

    /// anonymous mode
    open dynamic var anonymousModeEnabled = false

// MARK: Nerd mode

    ///
    open dynamic var nerdModeEnabled = false

    ///
    open dynamic var nerdModeForceIPv4 = false

    ///
    open dynamic var nerdModeForceIPv6 = false

    ///
    open dynamic var nerdModeQosEnabled = false // nkom: qos disabled by default

// MARK: Debug properties

    ///
    open dynamic var debugUnlocked = false

    // loop mode

    ///
    open dynamic var debugLoopMode = false

    ///
    open dynamic var debugLoopModeMaxTests: UInt = 0

    ///
    open dynamic var debugLoopModeMinDelay: UInt = 0

    // control server

    ///
    open dynamic var debugControlServerCustomizationEnabled = false

    ///
    open dynamic var debugControlServerHostname: String?

    ///
    open dynamic var debugControlServerPort: UInt = 0

    ///
    open dynamic var debugControlServerUseSSL = false

    // map server

    ///
    open dynamic var debugMapServerCustomizationEnabled = false

    ///
    open dynamic var debugMapServerHostname: String?

    ///
    open dynamic var debugMapServerPort: UInt = 0

    ///
    open dynamic var debugMapServerUseSSL = false

    // logging

    ///
    open dynamic var debugLoggingEnabled = false

    ///
    fileprivate override init() {
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

            "debugLoggingEnabled"
        ])
    }

    ///
    fileprivate func bindKeyPaths(_ keyPaths: [String]) {
        for keyPath in keyPaths {
            if let value = UserDefaults.getDataFor(key: keyPath) {
                setValue(value, forKey: keyPath)
            }

            // Start observing
            addObserver(self, forKeyPath: keyPath, options: .new, context: nil)
        }
    }

    ///
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let newValue = change?[NSKeyValueChangeKey.newKey], let kp = keyPath {
            logger.debugExec() {
                let oldValue = UserDefaults.getDataFor(key: kp)
                logger.debug("Settings changed for keyPath '\(keyPath)' from '\(oldValue)' to '\(newValue)'")
            }

            UserDefaults.storeDataFor(key: kp, obj: newValue)
        }
    }
}
