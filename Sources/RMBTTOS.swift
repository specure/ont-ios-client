//
//  RMBTTOS.swift
//  RMBT
//
//  Created by Benjamin Pucher on 18.09.14.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

import Foundation

///
public class RMBTTOS: NSObject {

    ///
    private let TOS_VERSION_KEY: String = "tos_version"

    ///
    public dynamic var lastAcceptedVersion: UInt // UInt correct? // dynamic?

    ///
    public var currentVersion: UInt // UInt correct?

    ///
    public static let sharedTOS = RMBTTOS()

    ///
    override public init() {
        if let tosVersionNumber = NSUserDefaults.standardUserDefaults().objectForKey(TOS_VERSION_KEY) as? UInt {
            self.lastAcceptedVersion = tosVersionNumber
        } else {
            self.lastAcceptedVersion = 0
        }

        self.currentVersion = UInt(RMBT_TOS_VERSION)
    }

    ///
    public func isCurrentVersionAccepted() -> Bool {
        return self.lastAcceptedVersion >= UInt(currentVersion) // is this correct?
    }

    ///
    public func acceptCurrentVersion() {
        lastAcceptedVersion = UInt(currentVersion)

        NSUserDefaults.standardUserDefaults().setObject(lastAcceptedVersion, forKey: TOS_VERSION_KEY)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    ///
    public func declineCurrentVersion() {
        lastAcceptedVersion = UInt(currentVersion) > 0 ? UInt(currentVersion) - 1 : 0 // go to previous version or 0 if not accepted

        NSUserDefaults.standardUserDefaults().setObject(lastAcceptedVersion, forKey: TOS_VERSION_KEY)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}
