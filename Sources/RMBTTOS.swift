//
//  RMBTTOS.swift
//  RMBT
//
//  Created by Benjamin Pucher on 18.09.14.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

import Foundation

///
class RMBTTOS: NSObject {

    ///
    private let TOS_VERSION_KEY: String = "tos_version"

    ///
    dynamic var lastAcceptedVersion: UInt // UInt correct?

    ///
    var currentVersion: UInt // UInt correct?

    ///
    static let sharedTOS = RMBTTOS()

    ///
    override init() {
        if let tosVersionNumber = NSUserDefaults.standardUserDefaults().objectForKey(TOS_VERSION_KEY) as? UInt {
            self.lastAcceptedVersion = tosVersionNumber
        } else {
            self.lastAcceptedVersion = 0
        }

        self.currentVersion = UInt(RMBT_TOS_VERSION)
    }

    ///
    func isCurrentVersionAccepted() -> Bool {
        return self.lastAcceptedVersion >= UInt(currentVersion) // is this correct?
    }

    ///
    func acceptCurrentVersion() {
        lastAcceptedVersion = UInt(currentVersion)

        NSUserDefaults.standardUserDefaults().setObject(lastAcceptedVersion, forKey: TOS_VERSION_KEY)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    ///
    func declineCurrentVersion() {
        lastAcceptedVersion = UInt(currentVersion) > 0 ? UInt(currentVersion) - 1 : 0 // go to previous version or 0 if not accepted

        NSUserDefaults.standardUserDefaults().setObject(lastAcceptedVersion, forKey: TOS_VERSION_KEY)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}
