//
//  QOSHTTPProxyTest.swift
//  RMBT
//
//  Created by Benjamin Pucher on 05.12.14.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

import Foundation

///
class QOSHTTPProxyTest: QOSTest {

    private let PARAM_URL = "url"
    private let PARAM_RANGE = "range"

    private let PARAM_DOWNLOAD_TIMEOUT = "download_timeout"
    private let PARAM_CONNECTION_TIMEOUT = "conn_timeout"

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
        return super.description + ", [downloadTimeout: \(downloadTimeout), connectionTimeout: \(connectionTimeout), url: \(url), range: \(range)]"
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
    override func getType() -> QOSTestType! {
        return .HttpProxy
    }

}
