//
//  QOSHTTPProxyTestExecutor.swift
//  RMBT
//
//  Created by Benjamin Pucher on 19.01.15.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

import Foundation
import AFNetworking

///
typealias HTTPProxyTestExecutor = QOSHTTPProxyTestExecutor<QOSHTTPProxyTest>

///
class QOSHTTPProxyTestExecutor<T: QOSHTTPProxyTest>: QOSTestExecutorClass<T> {

    private let RESULT_HTTP_PROXY_STATUS    = "http_result_status"
    private let RESULT_HTTP_PROXY_DURATION  = "http_result_duration"
    private let RESULT_HTTP_PROXY_LENGTH    = "http_result_length"
    private let RESULT_HTTP_PROXY_HEADER    = "http_result_header"
    private let RESULT_HTTP_PROXY_RANGE     = "http_objective_range"
    private let RESULT_HTTP_PROXY_URL       = "http_objective_url"
    private let RESULT_HTTP_PROXY_HASH      = "http_result_hash"

    //

    ///
    private var requestStartTimeTicks: UInt64 = 0

    //

    ///
    override init(controlConnection: QOSControlConnection, delegateQueue: dispatch_queue_t, testObject: T, speedtestStartTime: UInt64) {
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

            let manager: AFHTTPRequestOperationManager = AFHTTPRequestOperationManager()

            // add range header if it exists
            if let range = testObject.range {
                manager.requestSerializer.setValue(range, forHTTPHeaderField: "Range")
            }

            // set timeout (timeoutInterval is in seconds)
            manager.requestSerializer.timeoutInterval = nsToSec(testObject.downloadTimeout) // TODO: is this the correct timeout?

            // add text/html to the accepted content types
            // manager.responseSerializer.acceptableContentTypes = manager.responseSerializer.acceptableContentTypes.setByAddingObject("text/html")
            manager.responseSerializer = AFHTTPResponseSerializer()

            // generate url request

            let request: NSMutableURLRequest
            do {
                request = try manager.requestSerializer.requestWithMethod("GET", URLString: url, parameters: [:], error: ())
            } catch {
                // check error (TODO: check more...)
                return testDidFail()
            }

            // set request timeout
            request.timeoutInterval = nsToSec(testObject.connectionTimeout) // TODO: is this the correct timeout?

            // create request operation
            let requestOperation = manager.HTTPRequestOperationWithRequest(request, success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) -> Void in

                self.qosLog.debug("GET SUCCESS")

                // compute duration
                let durationInNanoseconds = getTimeDifferenceInNanoSeconds(self.requestStartTimeTicks)
                self.testResult.set(self.RESULT_HTTP_PROXY_DURATION, number: durationInNanoseconds)

                // set other result values
                self.testResult.set(self.RESULT_HTTP_PROXY_STATUS, value: operation.response.statusCode)
                self.testResult.set(self.RESULT_HTTP_PROXY_LENGTH, number: operation.response.expectedContentLength)

                // compute md5
                if let r = responseObject as? NSData {
                    self.qosLog.debug("ITS NSDATA!")

                    self.testResult.set(self.RESULT_HTTP_PROXY_HASH, value: r.MD5().hexString()) // TODO: improve
                }

                // loop through headers
                var headerString: String = ""
                for (headerName, headerValue) in operation.response.allHeaderFields {
                    headerString += "\(headerName): \(headerValue)\n"
                }

                self.testResult.set(self.RESULT_HTTP_PROXY_HEADER, value: headerString)

                ///
                self.testDidSucceed()
                ///

            }, failure: { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in

                self.qosLog.debug("GET FAILURE")
                self.qosLog.debug("\(error.description)")

                if error != nil && error.code == NSURLErrorTimedOut {
                    // timeout
                    self.testDidTimeout()
                } else {
                    self.testDidFail()
                }
            })

            // prevent redirect
            requestOperation.setRedirectResponseBlock { (connection: NSURLConnection!, request: NSURLRequest!, redirectResponse: NSURLResponse!) -> NSURLRequest! in
                if redirectResponse == nil {
                    return request
                } else {
                    requestOperation.cancel()
                    self.qosLog.debug("prevented redirect from \(request.URL!.absoluteString) to \(redirectResponse.URL!.absoluteString)")
                    return nil
                }
            }

            // set start time
            requestStartTimeTicks = getCurrentTimeTicks()

            // execute get
            manager.operationQueue.addOperation(requestOperation)
        }
    }

    ///
    override func testDidTimeout() {
        testResult.set(RESULT_HTTP_PROXY_HASH, value: "TIMEOUT")

        testResult.set(RESULT_HTTP_PROXY_STATUS, value: "")
        testResult.set(RESULT_HTTP_PROXY_LENGTH, value: 0)
        testResult.set(RESULT_HTTP_PROXY_HEADER, value: "")

        super.testDidTimeout()
    }

    ///
    override func testDidFail() {
        testResult.set(RESULT_HTTP_PROXY_HASH, value: "ERROR")

        testResult.set(RESULT_HTTP_PROXY_STATUS, value: "")
        testResult.set(RESULT_HTTP_PROXY_LENGTH, value: 0)
        testResult.set(RESULT_HTTP_PROXY_HEADER, value: "")

        super.testDidFail()
    }

    ///
    override func needsControlConnection() -> Bool {
        return false
    }

}
