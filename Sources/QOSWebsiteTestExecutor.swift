//
//  QOSWebsiteTestExecutor.swift
//  RMBT
//
//  Created by Benjamin Pucher on 20.01.15.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

import Foundation

///
typealias WebsiteTestExecutor = QOSWebsiteTestExecutor<QOSWebsiteTest>

///
class QOSWebsiteTestExecutor<T: QOSWebsiteTest>: QOSTestExecutorClass<T> {

    private let RESULT_WEBSITE_URL      = "website_objective_url"
    private let RESULT_WEBSITE_TIMEOUT  = "website_objective_timeout"
    private let RESULT_WEBSITE_DURATION = "website_result_duration"
    private let RESULT_WEBSITE_STATUS   = "website_result_status"
    private let RESULT_WEBSITE_INFO     = "website_result_info"
    private let RESULT_WEBSITE_RX_BYTES = "website_result_rx_bytes"
    private let RESULT_WEBSITE_TX_BYTES = "website_result_tx_bytes"

    //

    ///
    // private var webView: UIWebView?

//    private let webViewDelegate = WebViewDelegate()

    private var requestStartTimeTicks: UInt64 = 0

    //

    ///
    override init(controlConnection: QOSControlConnection, delegateQueue: dispatch_queue_t, testObject: T, speedtestStartTime: UInt64) {
        super.init(controlConnection: controlConnection, delegateQueue: delegateQueue, testObject: testObject, speedtestStartTime: speedtestStartTime)
    }

    ///
    override func startTest() {
        super.startTest()

        testResult.set(RESULT_WEBSITE_URL, value: testObject.url)
        testResult.set(RESULT_WEBSITE_TIMEOUT, number: testObject.timeout)
    }

    ///
    override func executeTest() {

        /* if let url = testObject.url {

            qosLog.debug("EXECUTING WEBSITE TEST")

            dispatch_async(dispatch_get_main_queue()) {
                let webView = UIWebView()
                webView.delegate = self.webViewDelegate

                let request: NSURLRequest = NSURLRequest(URL: NSURL(string: "https://www.alladin.at")!)

                webView.loadRequest(request)

                logger.debug("AFTER LOAD REQUEST")
            }
        } */
    }

    ///
    override func needsControlConnection() -> Bool {
        return false
    }

// MARK: UIWebViewDelegate methods

    /* func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        return true
    }

    func webViewDidStartLoad(webView: UIWebView) {
        logger.debug("WEB VIEW DID START LOAD")

        requestStartTimeTicks = getCurrentTimeTicks()
    }

    func webViewDidFinishLoad(webView: UIWebView) {
        logger.debug("WEB VIEW DID FINISH LOAD")

        let durationInNanoseconds = getTimeDifferenceInNanoSeconds(self.requestStartTimeTicks)
        self.testResult.resultDictionary[self.RESULT_WEBSITE_DURATION] = NSNumber(unsignedLongLong: durationInNanoseconds)

        self.callFinishCallback()
    }

    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        logger.debug("WEB VIEW DID FAIL LOAD, \(error)")
    } */

// MARK: other methods

}
