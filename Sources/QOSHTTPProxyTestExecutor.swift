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
import Alamofire

///
typealias HTTPProxyTestExecutor = QOSHTTPProxyTestExecutor<QOSHTTPProxyTest>

///
class QOSHTTPProxyTestExecutor<T: QOSHTTPProxyTest>: QOSTestExecutorClass<T> {

    fileprivate let RESULT_HTTP_PROXY_STATUS    = "http_result_status"
    fileprivate let RESULT_HTTP_PROXY_DURATION  = "http_result_duration"
    fileprivate let RESULT_HTTP_PROXY_LENGTH    = "http_result_length"
    fileprivate let RESULT_HTTP_PROXY_HEADER    = "http_result_header"
    fileprivate let RESULT_HTTP_PROXY_RANGE     = "http_objective_range"
    fileprivate let RESULT_HTTP_PROXY_URL       = "http_objective_url"
    fileprivate let RESULT_HTTP_PROXY_HASH      = "http_result_hash"

    //

    ///
    fileprivate var requestStartTimeTicks: UInt64 = 0

    ///
    fileprivate var alamofireManager: Alamofire.SessionManager! // !

    //

    ///
    override init(controlConnection: QOSControlConnection, delegateQueue: DispatchQueue, testObject: T, speedtestStartTime: UInt64) {
        super.init(controlConnection: controlConnection, delegateQueue: delegateQueue, testObject: testObject, speedtestStartTime: speedtestStartTime)
    }

    ///
    override func startTest() {
        super.startTest()

        testResult.set(RESULT_HTTP_PROXY_RANGE, value: testObject.range as AnyObject?)
        testResult.set(RESULT_HTTP_PROXY_URL, value: testObject.url as AnyObject?)
        testResult.set(RESULT_HTTP_PROXY_DURATION, value: -1 as AnyObject?)
    }

    ///
    override func executeTest() {

        // TODO: check testObject.url
        if let url = testObject.url {

            qosLog.debug("EXECUTING HTTP PROXY TEST")

            /////////
            let configuration = URLSessionConfiguration.ephemeral

            let timeout = nsToSec(testObject.downloadTimeout)
            qosLog.debug("TIMEOUT sec: \(timeout)")

            configuration.timeoutIntervalForRequest = timeout
            configuration.timeoutIntervalForResource = timeout

            configuration.allowsCellularAccess = true
            //configuration.HTTPShouldUsePipelining = true

            var additonalHeaderFields = [String: AnyObject]()

            // Set user agent
            if let userAgent = UserDefaults.getRequestUserAgent() { //.standard.string(forKey: "UserAgent") {
                additonalHeaderFields["User-Agent"] = userAgent as AnyObject?
            }

            // add range header if it exists
            if let range = testObject.range {
                additonalHeaderFields["Range"] = range as AnyObject?
            }

            configuration.httpAdditionalHeaders = additonalHeaderFields

            alamofireManager = Alamofire.SessionManager(configuration: configuration)

            // prevent redirect
            let delegate = alamofireManager.delegate

            delegate.taskWillPerformHTTPRedirection = { session, task, response, request in
                return URLRequest(url: URL(string: url)!) // see https://github.com/Alamofire/Alamofire/pull/424/files
            }

            ////

            // set start time
            requestStartTimeTicks = getCurrentTimeTicks()

            ////

            //alamofireManager.request(.get, url, parameters: [:], encoding: .URL, headers: nil)
            alamofireManager.request(url, method: .get, parameters: [:], encoding: URLEncoding.default, headers: nil)
            
                .responseJSON { response in
                    
                    //to get status code
                    if let status = response.response?.statusCode {
                        switch status {
                            case 200, 201:
                                debugPrint(response)
                                
                                self.qosLog.debug("GET SUCCESS")
        
                                // compute duration
                                let durationInNanoseconds = getTimeDifferenceInNanoSeconds(self.requestStartTimeTicks)
                                self.testResult.set(self.RESULT_HTTP_PROXY_DURATION, number: durationInNanoseconds)
        
                                // set other result values
                                self.testResult.set(self.RESULT_HTTP_PROXY_STATUS, value: response.response?.statusCode)
                                self.testResult.set(self.RESULT_HTTP_PROXY_LENGTH, number: response.response?.expectedContentLength)
        
                                // compute md5
                                if let r = response.data {
                                    self.qosLog.debug("ITS NSDATA!")
        
                                    self.testResult.set(self.RESULT_HTTP_PROXY_HASH, value: r.MD5().hexString()) // TODO: improve
                                }
        
                                // loop through headers
                                var headerString: String = ""
                                if let allHeaderFields = response.response?.allHeaderFields {
                                    for (headerName, headerValue) in allHeaderFields {
                                        headerString += "\(headerName): \(headerValue)\n"
                                    }
                                }
        
                                self.testResult.set(self.RESULT_HTTP_PROXY_HEADER, value: headerString)
        
                                ///
                            self.testDidSucceed()
                        case 408:
                            // timeout
                            self.testDidTimeout()
                        default:
                            logger.debug("error msg from server: \(String(describing: response.result.value))")
                            
                            //to get JSON return value
                            if let result = response.result.value {
                                let JSON = result as! NSDictionary
                                print(JSON)
                                
                                self.qosLog.debug("GET FAILURE")
                                self.qosLog.debug("\(String(describing: response.error))")

                                self.testDidFail()
                            }
                        }
                    }
                    
                    
                    
//                .validate()
//                .responseData { (response: DataResponse<Data>) in
//                    switch response.result {
//                    case .success():
//
//                        self.qosLog.debug("GET SUCCESS")
//
//                        // compute duration
//                        let durationInNanoseconds = getTimeDifferenceInNanoSeconds(self.requestStartTimeTicks)
//                        self.testResult.set(self.RESULT_HTTP_PROXY_DURATION, number: durationInNanoseconds)
//
//                        // set other result values
//                        self.testResult.set(self.RESULT_HTTP_PROXY_STATUS, value: response.response?.statusCode)
//                        self.testResult.set(self.RESULT_HTTP_PROXY_LENGTH, number: response.response?.expectedContentLength)
//
//                        // compute md5
//                        if let r = response.result.value {
//                            self.qosLog.debug("ITS NSDATA!")
//
//                            self.testResult.set(self.RESULT_HTTP_PROXY_HASH, value: r.MD5().hexString()) // TODO: improve
//                        }
//
//                        // loop through headers
//                        var headerString: String = ""
//                        if let allHeaderFields = response.response?.allHeaderFields {
//                            for (headerName, headerValue) in allHeaderFields {
//                                headerString += "\(headerName): \(headerValue)\n"
//                            }
//                        }
//
//                        self.testResult.set(self.RESULT_HTTP_PROXY_HEADER, value: headerString)
//
//                        ///
//                        self.testDidSucceed()
//                        ///
//
//                    case .failure(let error):
//                        self.qosLog.debug("GET FAILURE")
//                        self.qosLog.debug("\(error.localizedDescription)")
//
//                        if error. == NSURLErrorTimedOut {
//                            // timeout
//                            self.testDidTimeout()
//                        } else {
//                            self.testDidFail()
//                        }
//                    }
                }
        }
    }

    ///
    override func testDidTimeout() {
        testResult.set(RESULT_HTTP_PROXY_HASH, value: "TIMEOUT" as AnyObject?)

        testResult.set(RESULT_HTTP_PROXY_STATUS, value: "" as AnyObject?)
        testResult.set(RESULT_HTTP_PROXY_LENGTH, value: 0 as AnyObject?)
        testResult.set(RESULT_HTTP_PROXY_HEADER, value: "" as AnyObject?)

        super.testDidTimeout()
    }

    ///
    override func testDidFail() {
        testResult.set(RESULT_HTTP_PROXY_HASH, value: "ERROR" as AnyObject?)

        testResult.set(RESULT_HTTP_PROXY_STATUS, value: "" as AnyObject?)
        testResult.set(RESULT_HTTP_PROXY_LENGTH, value: 0 as AnyObject?)
        testResult.set(RESULT_HTTP_PROXY_HEADER, value: "" as AnyObject?)

        super.testDidFail()
    }

    ///
    override func needsControlConnection() -> Bool {
        return false
    }

}
