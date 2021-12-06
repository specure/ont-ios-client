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
class QOSHTTPProxyTest: QOSTest {

    fileprivate let PARAM_URL = "url"
    fileprivate let PARAM_RANGE = "range"

    fileprivate let PARAM_DOWNLOAD_TIMEOUT = "download_timeout"
    fileprivate let PARAM_CONNECTION_TIMEOUT = "conn_timeout"

    //

    /// The download timeout in nano seconds of the http proxy test (optional) (provided by control server)
    var downloadTimeout: UInt64 = 10_000_000_000 // default download timeout value

    /// The connection timeout in nano seconds of the http proxy test (optional) (provided by control server)
    var connectionTimeout: UInt64 = 5_000_000_000 // default connection timeout value

    /// The url of the http proxy test (provided by control server)
    var url: String?

    /// The range of the http proxy test (optional) (provided by control server)
    var range: String?

    //

    ///
    override var description: String {
        return super.description + ", [downloadTimeout: \(downloadTimeout), connectionTimeout: \(connectionTimeout), url: \(String(describing: url)), range: \(String(describing: range))]"
    }

    //

    ///
    override init(testParameters: QOSTestParameters) {
        // url
        if let url = testParameters[PARAM_URL] as? String {
            // TODO: length check on url?
            self.url = url
        }

        // range
        if let range = testParameters[PARAM_RANGE] as? String {
            self.range = range
        }

        // downloadTimeout
        if let downloadTimeoutString = testParameters[PARAM_DOWNLOAD_TIMEOUT] as? NSString {
            let downloadTimeout = downloadTimeoutString.longLongValue
            if downloadTimeout > 0 {
                self.downloadTimeout = UInt64(downloadTimeout)
            }
        }

        // connectionTimeout
        if let connectionTimeoutString = testParameters[PARAM_CONNECTION_TIMEOUT] as? NSString {
            let connectionTimeout = connectionTimeoutString.longLongValue
            if connectionTimeout > 0 {
                self.connectionTimeout = UInt64(connectionTimeout)
            }
        }

        super.init(testParameters: testParameters)

        // set timeout
        self.timeout = max(downloadTimeout, connectionTimeout)
    }

    ///
    override func getType() -> QosMeasurementType! {
        return .HttpProxy
    }

}
