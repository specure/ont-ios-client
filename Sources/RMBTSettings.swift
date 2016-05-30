//
//  RMBTSettings.swift
//  RMBT
//
//  Created by Benjamin Pucher on 21.09.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation
import BlocksKit

///
class RMBTSettings: NSObject {

// MARK: Temporary app state (global variables)

    ///
    var mapOptionsSelection: RMBTMapOptionsSelection

// MARK: Persisted app state

    ///
    var testCounter: UInt = 0

    ///
    var previousTestStatus: String!

// MARK: User configurable properties

    ///
    var forceIPv4: Bool = false

    ///
    var publishPublicData: Bool = false

// MARK: Debug properties

    ///
    var debugUnlocked: Bool = false

    ///
    var debugForceIPv6: Bool = false

    // loop mode

    ///
    var debugLoopMode: Bool = false
    var debugLoopModeMaxTests: UInt = 0
    var debugLoopModeMinDelay: UInt = 0
    var debugLoopModeSkipQOS: Bool = false

    // control server

    ///
    var debugControlServerCustomizationEnabled: Bool = false
    var debugControlServerHostname: String!
    var debugControlServerPort: UInt = 0
    var debugControlServerUseSSL: Bool = false

    // map server

    ///
    var debugMapServerCustomizationEnabled: Bool = false
    var debugMapServerHostname: String!
    var debugMapServerPort: UInt = 0
    var debugMapServerUseSSL: Bool = false

    // logging

    ///
    var debugLoggingEnabled: Bool = false

    ///
    private static let _sharedSettings = RMBTSettings()

    /// TODO: remove later
    class func sharedSettings() -> RMBTSettings {
        return _sharedSettings
    }

    ///
    private override init() {
        mapOptionsSelection = RMBTMapOptionsSelection()

        super.init()

        bindKeyPaths([
            "testCounter",
            "previousTestStatus",

            "debugUnlocked",

            // general

            "forceIPv4",
            "debugForceIPv6",

            "publishPublicData",

            // loop mode

            "debugLoopMode",
            "debugLoopModeMaxTests",
            "debugLoopModeMinDelay",
            "debugLoopModeSkipQOS",

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

    private func bindKeyPaths(keyPaths: [String]) {
        for keyPath in keyPaths {
            if let value = NSUserDefaults.standardUserDefaults().objectForKey(keyPath) {
                setValue(value, forKey: keyPath)
            }

            // Start observing
            bk_addObserverForKeyPath(keyPath, options: .New, task: { (obj: AnyObject!, change: [NSObject : AnyObject]!) in
                let newValue = change[NSKeyValueChangeNewKey]

                NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: keyPath)
                NSUserDefaults.standardUserDefaults().synchronize()
            })
        }
    }
}
