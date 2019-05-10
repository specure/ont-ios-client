/*****************************************************************************************************
 * Copyright 2016 SPECURE GmbH
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
class AbstractBasicRequestBuilder {

    ///
    class func addBasicRequestValues(_ basicRequest: BasicRequest) {
        let infoDictionary = Bundle.main.infoDictionary! // !

        basicRequest.apiLevel = "" // always null on iOS...
        basicRequest.clientName = "RMBT"
        if RMBTConfig.sharedInstance.RMBT_USE_MAIN_LANGUAGE == true {
            basicRequest.language = RMBTConfig.sharedInstance.RMBT_MAIN_LANGUAGE
        } else {
            basicRequest.language = PREFFERED_LANGUAGE
        }
        basicRequest.product = "" // always null on iOS...

        Log.logger.debug("ADDING PREVIOUS TEST STATUS: \(String(describing: RMBTSettings.sharedSettings.previousTestStatus))")

        basicRequest.previousTestStatus = RMBTSettings.sharedSettings.previousTestStatus ?? RMBTTestStatus.None.rawValue
        basicRequest.softwareRevision = RMBTBuildInfoString()
        basicRequest.softwareVersion = infoDictionary["CFBundleShortVersionString"] as? String
        basicRequest.softwareVersionCode = infoDictionary["CFBundleVersion"] as? Int
        basicRequest.softwareVersionName = "0.3" // ??

        basicRequest.clientVersion = "0.3" // TODO: fix this on server side

        basicRequest.timezone = TimeZone.current.identifier
    }

}
