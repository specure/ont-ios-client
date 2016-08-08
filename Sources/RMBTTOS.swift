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
    private let TOS_VERSION_KEY = "tos_version"

    ///
    public dynamic var lastAcceptedVersion: Int

    ///
    public var currentVersion: Int

    ///
    public static let sharedTOS = RMBTTOS()

    ///
    override public init() {
        lastAcceptedVersion = NSUserDefaults.standardUserDefaults().integerForKey(TOS_VERSION_KEY) ?? 0
        currentVersion = RMBT_TOS_VERSION
    }

    ///
    public func isCurrentVersionAccepted() -> Bool {
        return lastAcceptedVersion >= currentVersion // is this correct?
    }

    ///
    public func acceptCurrentVersion() {
        lastAcceptedVersion = currentVersion

        NSUserDefaults.standardUserDefaults().setInteger(lastAcceptedVersion, forKey: TOS_VERSION_KEY)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    ///
    public func declineCurrentVersion() {
        lastAcceptedVersion = currentVersion > 0 ? currentVersion - 1 : 0 // go to previous version or 0 if not accepted

        NSUserDefaults.standardUserDefaults().setInteger(lastAcceptedVersion, forKey: TOS_VERSION_KEY)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
}
