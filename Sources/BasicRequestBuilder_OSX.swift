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
class BasicRequestBuilder: AbstractBasicRequestBuilder {

    ///
    override class func addBasicRequestValues(basicRequest: BasicRequest) {
        super.addBasicRequestValues(basicRequest)

        basicRequest.device = "DESKTOP" //currentDevice.model
        basicRequest.model = "??" //UIDeviceHardware.platform()
        basicRequest.osVersion = "10.11" //currentDevice.systemVersion
        basicRequest.platform = "OSX"
        basicRequest.clientType = "DESKTOP"
    }

}
