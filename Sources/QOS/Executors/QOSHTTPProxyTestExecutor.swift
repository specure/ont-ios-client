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
    fileprivate var alamofireManager: Alamofire.Session! // !
    
    fileprivate var request: DataRequest?

    //

    ///
    override init(controlConnection: QOSControlConnection?, delegateQueue: DispatchQueue, testObject: T, speedtestStartTime: UInt64) {
        super.init(controlConnection: controlConnection, delegateQueue: delegateQueue, testObject: testObject, speedtestStartTime: speedtestStartTime)
    }

    ///
    override func startTest() {
        super.startTest()

        testResult.set(RESULT_HTTP_PROXY_RANGE, value: testObject.range)
        testResult.set(RESULT_HTTP_PROXY_URL, value: testObject.url)
        testResult.set(RESULT_HTTP_PROXY_DURATION, value: -1)
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
            if let userAgent = UserDefaults.getRequestUserAgent() {
                additonalHeaderFields["User-Agent"] = userAgent as AnyObject?
            }

            // add range header if it exists
            if let range = testObject.range {
                additonalHeaderFields["Range"] = range as AnyObject?
            }

            configuration.httpAdditionalHeaders = additonalHeaderFields
            
            //It could be wrong update
            let redirector = Redirector(behavior: .modify({ (task, request, response) -> URLRequest? in
                return URLRequest(url: URL(string: url)!)
            }))
            
            alamofireManager = Session(configuration: configuration, redirectHandler: redirector)

            
            // prevent redirect
            let delegate = alamofireManager.delegate

//            delegate.taskWillPerformHTTPRedirection = { session, task, response, request in
//                return URLRequest(url: URL(string: url)!) // see https://github.com/Alamofire/Alamofire/pull/424/files
//            }

            ////

            // set start time
            requestStartTimeTicks = UInt64.getCurrentTimeTicks()

            ////

            //alamofireManager.request(.get, url, parameters: [:], encoding: .URL, headers: nil)
            request = alamofireManager.request(url, method: .get, parameters: [:], encoding: URLEncoding.default, headers: nil)
            
                .responseJSON { [weak self] response in
                    guard let strongSelf = self else { return }
                    //to get status code
                    if let status = response.response?.statusCode {
                        switch status {
                            // Added 206 by TB 30.08.17
                            case 200, 201, 206:
                                debugPrint(response)
                                
                                strongSelf.qosLog.debug("GET SUCCESS")
        
                                // compute duration
                                let durationInNanoseconds = UInt64.getTimeDifferenceInNanoSeconds(strongSelf.requestStartTimeTicks)
                                strongSelf.testResult.set(strongSelf.RESULT_HTTP_PROXY_DURATION, number: durationInNanoseconds)
        
                                // set other result values
                                strongSelf.testResult.set(strongSelf.RESULT_HTTP_PROXY_STATUS, value: response.response?.statusCode)
                                strongSelf.testResult.set(strongSelf.RESULT_HTTP_PROXY_LENGTH, number: response.response?.expectedContentLength)
        
                                // compute md5
                                if let r = response.data {
                                    strongSelf.qosLog.debug("ITS NSDATA!")
        
                                    strongSelf.testResult.set(strongSelf.RESULT_HTTP_PROXY_HASH, value: r.MD5().hexString()) // TODO: improve
                                }
        
                                // loop through headers
                                var headerString: String = ""
                                if let allHeaderFields = response.response?.allHeaderFields {
                                    for (headerName, headerValue) in allHeaderFields {
                                        headerString += "\(headerName): \(headerValue)\n"
                                    }
                                }
        
                                strongSelf.testResult.set(strongSelf.RESULT_HTTP_PROXY_HEADER, value: headerString)
        
                                ///
                            strongSelf.testDidSucceed()
                        case 408:
                            // timeout
                            strongSelf.testDidTimeout()
                        default:
                            let value = try? response.result.get()
                            Log.logger.debug("error msg from server: \(String(describing: value))")

                            
                            //to get JSON return value
                            if let result = value {
                                if let JSON = result as? NSDictionary {
                                    print(JSON)
                                }
                                
                                strongSelf.qosLog.debug("GET FAILURE")
                                strongSelf.qosLog.debug("\(String(describing: response.error))")

                                strongSelf.testDidFail()
                            }
                        }
                    }
                    
                    
// Original solution
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
        testResult.set(RESULT_HTTP_PROXY_HASH, value: "TIMEOUT" as String?)

        testResult.set(RESULT_HTTP_PROXY_STATUS, value: "")
        testResult.set(RESULT_HTTP_PROXY_LENGTH, value: 0)
        testResult.set(RESULT_HTTP_PROXY_HEADER, value: "")

        request?.cancel()
        super.testDidTimeout()
    }

    ///
    override func testDidFail() {
        testResult.set(RESULT_HTTP_PROXY_HASH, value: "ERROR")

        testResult.set(RESULT_HTTP_PROXY_STATUS, value: "")
        testResult.set(RESULT_HTTP_PROXY_LENGTH, value: 0)
        testResult.set(RESULT_HTTP_PROXY_HEADER, value: "")

        request?.cancel()
        super.testDidFail()
    }

    ///
    override func needsControlConnection() -> Bool {
        return false
    }

}
