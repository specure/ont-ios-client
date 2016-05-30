//
//  QOSNonTransparentProxyTestExecutor.swift
//  RMBT
//
//  Created by Benjamin Pucher on 09.12.14.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

///
typealias NonTransparentProxyTestExecutor = QOSNonTransparentProxyTestExecutor<QOSNonTransparentProxyTest>

///
class QOSNonTransparentProxyTestExecutor<T: QOSNonTransparentProxyTest>: QOSTestExecutorClass<T>, GCDAsyncSocketDelegate {

    private let RESULT_NONTRANSPARENT_PROXY_RESPONSE    = "nontransproxy_result_response"
    private let RESULT_NONTRANSPARENT_PROXY_REQUEST     = "nontransproxy_objective_request"
    private let RESULT_NONTRANSPARENT_PROXY_PORT        = "nontransproxy_objective_port"
    private let RESULT_NONTRANSPARENT_PROXY_TIMEOUT     = "nontransproxy_objective_timeout"
    private let RESULT_NONTRANSPARENT_PROXY_STATUS      = "nontransproxy_result"

    //

    let TAG_TASK_NTPTEST = 2001

    //

    let TAG_NTPTEST_REQUEST = -1

    ///
    private let socketQueue = dispatch_queue_create("com.specure.rmbt.qos.ntp.socketQueue", DISPATCH_QUEUE_CONCURRENT)

    ///
    private var ntpTestSocket: GCDAsyncSocket!

    ///
    private var gotReply = false

    //

    ///
    override init(controlConnection: QOSControlConnection, delegateQueue: dispatch_queue_t, testObject: T, speedtestStartTime: UInt64) {
        super.init(controlConnection: controlConnection, delegateQueue: delegateQueue, testObject: testObject, speedtestStartTime: speedtestStartTime)
    }

    ///
    override func startTest() {
        super.startTest()

        testResult.set(RESULT_NONTRANSPARENT_PROXY_TIMEOUT, number: testObject.timeout)
        testResult.set(RESULT_NONTRANSPARENT_PROXY_REQUEST, value: testObject.request?.stringByRemovingLastNewline())
    }

    ///
    override func executeTest() {
        if let port = testObject.port {
            testResult.set(RESULT_NONTRANSPARENT_PROXY_PORT, number: port)

            qosLog.debug("EXECUTING NON TRANSPARENT PROXY TEST")
            qosLog.debug("requesting NTPTEST on port \(port)")

            // request NTPTEST
            controlConnection.sendTaskCommand("NTPTEST \(port)", withTimeout: timeoutInSec, forTaskId: testObject.qosTestId, tag: TAG_TASK_NTPTEST)
        }
    }

    ///
    override func testDidSucceed() {
        testResult.set(RESULT_NONTRANSPARENT_PROXY_STATUS, value: "OK")

        super.testDidSucceed()
    }

    ///
    override func testDidTimeout() {
        testResult.set(RESULT_NONTRANSPARENT_PROXY_STATUS, value: "TIMEOUT")

        super.testDidTimeout()
    }

    ///
    override func testDidFail() {
        qosLog.debug("NTP: TEST DID FAIL")

        testResult.set(RESULT_NONTRANSPARENT_PROXY_RESPONSE, value: "")
        testResult.set(RESULT_NONTRANSPARENT_PROXY_STATUS, value: "ERROR")

        super.testDidFail()
    }

// MARK: QOSControlConnectionDelegate methods

    override func controlConnection(connection: QOSControlConnection, didReceiveTaskResponse response: String, withTaskId taskId: UInt, tag: Int) {
        qosLog.debug("CONTROL CONNECTION DELEGATE FOR TASK ID \(taskId), WITH TAG \(tag), WITH STRING \(response)")

        switch tag {
        case TAG_TASK_NTPTEST:
            qosLog.debug("NTPTEST response: \(response)")

            if response.hasPrefix("OK") {

                // create client socket
                ntpTestSocket = GCDAsyncSocket(delegate: self, delegateQueue: delegateQueue, socketQueue: socketQueue)

                // connect client socket
                do {
                    try ntpTestSocket.connectToHost(testObject.serverAddress, onPort: testObject.port!, withTimeout: timeoutInSec)
                } catch {
                    // there was an error
                    qosLog.debug("connection error \(error)")

                    return testDidFail()
                }
            } else {
                testDidFail()
            }

        default:
            // do nothing
            qosLog.debug("default case: do nothing")
        }
    }

// MARK: GCDAsyncSocketDelegate methods

    ///
    @objc func socket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        if sock == ntpTestSocket {
            qosLog.debug("will send \(testObject.request) to the server")

            // write request message and read response
            SocketUtils.writeLine(ntpTestSocket, line: testObject.request!, withTimeout: timeoutInSec, tag: TAG_NTPTEST_REQUEST) // TODO: what if request is nil?
            SocketUtils.readLine(ntpTestSocket, tag: TAG_NTPTEST_REQUEST, withTimeout: timeoutInSec)
        }
    }

    ///
    @objc func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        if sock == ntpTestSocket {
            switch tag {
            case TAG_NTPTEST_REQUEST:

                gotReply = true

                qosLog.debug("\(String(data: data, encoding: NSASCIIStringEncoding))")

                if let response = SocketUtils.parseResponseToString(data) {
                    qosLog.debug("response: \(response)")

                    testResult.set(RESULT_NONTRANSPARENT_PROXY_RESPONSE, value: response.stringByRemovingLastNewline())

                    testDidSucceed()
                } else {
                    qosLog.debug("NO RESP")
                    testDidFail()
                }

            default:
                // do nothing
                qosLog.debug("do nothing")
            }
        }
    }

    ///
    @objc func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        // if (err != nil && err.code == GCDAsyncSocketConnectTimeoutError) { //check for timeout
        //    return testDidTimeout()
        // }
        qosLog.debug("DID DISC gotreply (before?): \(gotReply), error: \(err)")
        if !gotReply {
            testDidFail()
        }
    }

}
