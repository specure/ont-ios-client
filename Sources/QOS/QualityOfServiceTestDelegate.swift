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
@objc public protocol QualityOfServiceTestDelegate {

    ///
    func qualityOfServiceTestDidStart(_ test: QualityOfServiceTest)

    ///
    func qualityOfServiceTestDidStop(_ test: QualityOfServiceTest)

    ///
    func qualityOfServiceTest(_ test: QualityOfServiceTest, didFinishWithResults results: [QOSTestResult])

    ///
    func qualityOfServiceTest(_ test: QualityOfServiceTest, didFailWithError: NSError!) // TODO: remove !

    ///
    func qualityOfServiceTest(_ test: QualityOfServiceTest, didFetchTestTypes testTypes: [String]) //testTypes is array of QosMeasurementType

    ///
    func qualityOfServiceTest(_ test: QualityOfServiceTest, didFinishTestType testType: String) //testType is QosMeasurementType

    ///
    func qualityOfServiceTest(_ test: QualityOfServiceTest, didProgressToValue progress: Float)
}
