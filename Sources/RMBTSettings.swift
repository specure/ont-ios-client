//
//  RMBTSettings.swift
//  RMBT
//
//  Created by Benjamin Pucher on 21.09.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
public class RMBTSettings: NSObject {

    ///
    public static let sharedSettings = RMBTSettings()

// MARK: Temporary app state (global variables)

    ///
    public dynamic var mapOptionsSelection: RMBTMapOptionsSelection

// MARK: Persisted app state

    ///
    public dynamic var testCounter: UInt = 0

    ///
    public dynamic var previousTestStatus: String?

// MARK: User configurable properties

    ///
    public dynamic var publishPublicData = false // only for akos

    /// anonymous mode
    public dynamic var anonymousModeEnabled = false

// MARK: Nerd mode

    ///
    public dynamic var nerdModeEnabled = false

    ///
    public dynamic var nerdModeForceIPv4 = false

    ///
    public dynamic var nerdModeForceIPv6 = false

    ///
    public dynamic var nerdModeQosEnabled = false // nkom: qos disabled by default

// MARK: Debug properties

    ///
    public dynamic var debugUnlocked = false

    // loop mode

    ///
    public dynamic var debugLoopMode = false

    ///
    public dynamic var debugLoopModeMaxTests: UInt = 0

    ///
    public dynamic var debugLoopModeMinDelay: UInt = 0

    // control server

    ///
    public dynamic var debugControlServerCustomizationEnabled = false

    ///
    public dynamic var debugControlServerHostname: String?

    ///
    public dynamic var debugControlServerPort: UInt = 0

    ///
    public dynamic var debugControlServerUseSSL = false

    // map server

    ///
    public dynamic var debugMapServerCustomizationEnabled = false

    ///
    public dynamic var debugMapServerHostname: String?

    ///
    public dynamic var debugMapServerPort: UInt = 0

    ///
    public dynamic var debugMapServerUseSSL = false

    // logging

    ///
    public dynamic var debugLoggingEnabled = false

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
    private func bindKeyPaths(keyPaths: [String]) {
        for keyPath in keyPaths {
            if let value = NSUserDefaults.standardUserDefaults().objectForKey(keyPath) {
                setValue(value, forKey: keyPath)
            }

            // Start observing
            addObserver(self, forKeyPath: keyPath, options: .New, context: nil)
        }
    }

    ///
    public override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if let newValue = change?[NSKeyValueChangeNewKey], kp = keyPath {
            logger.debugExec() {
                let oldValue = NSUserDefaults.standardUserDefaults().objectForKey(kp)
                logger.debug("Settings changed for keyPath '\(keyPath)' from '\(oldValue)' to '\(newValue)'")
            }

            NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: kp)
            NSUserDefaults.standardUserDefaults().synchronize()
        }
    }
}
