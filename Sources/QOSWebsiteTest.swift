/*****************************************************************************************************
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
class QOSWebsiteTest: QOSTest {

    fileprivate let PARAM_URL = "url"

    //

    /// The url of the website test (provided by control server)
    var url: String?

    //

    ///
    override var description: String {
        return super.description + ", [url: \(String(describing: url))]"
    }

    //

    ///
    override init(testParameters: QOSTestParameters) {
        // url
        if let url = testParameters[PARAM_URL] as? String {
            // TODO: length check on url?
            self.url = url
        }

        super.init(testParameters: testParameters)
    }

    ///
    override func getType() -> QosMeasurementType! {
        return .WEBSITE
    }
}
