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
open class RMBTTOS: NSObject {

    ///
    fileprivate let TOS_VERSION_KEY = "tos_version"

    ///
    open dynamic var lastAcceptedVersion: Int

    ///
    open var currentVersion: Int

    ///
    open static let sharedTOS = RMBTTOS()

    ///
    override public init() {
        lastAcceptedVersion = UserDefaults.standard.integer(forKey: TOS_VERSION_KEY) 
        currentVersion = RMBT_TOS_VERSION
    }

    ///
    open func isCurrentVersionAccepted() -> Bool {
        return lastAcceptedVersion >= currentVersion // is this correct?
    }

    ///
    open func acceptCurrentVersion() {
        lastAcceptedVersion = currentVersion

        UserDefaults.standard.set(lastAcceptedVersion, forKey: TOS_VERSION_KEY)
        UserDefaults.standard.synchronize()
    }

    ///
    open func declineCurrentVersion() {
        lastAcceptedVersion = currentVersion > 0 ? currentVersion - 1 : 0 // go to previous version or 0 if not accepted

        UserDefaults.standard.set(lastAcceptedVersion, forKey: TOS_VERSION_KEY)
        UserDefaults.standard.synchronize()
    }
}
