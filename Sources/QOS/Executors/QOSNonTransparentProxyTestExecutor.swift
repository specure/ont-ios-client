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
import CocoaAsyncSocket

///
typealias NonTransparentProxyTestExecutor = QOSNonTransparentProxyTestExecutor<QOSNonTransparentProxyTest>

///
class QOSNonTransparentProxyTestExecutor<T: QOSNonTransparentProxyTest>: QOSTestExecutorClass<T>, GCDAsyncSocketDelegate {

    fileprivate let RESULT_NONTRANSPARENT_PROXY_RESPONSE    = "nontransproxy_result_response"
    fileprivate let RESULT_NONTRANSPARENT_PROXY_REQUEST     = "nontransproxy_objective_request"
    fileprivate let RESULT_NONTRANSPARENT_PROXY_PORT        = "nontransproxy_objective_port"
    fileprivate let RESULT_NONTRANSPARENT_PROXY_TIMEOUT     = "nontransproxy_objective_timeout"
    fileprivate let RESULT_NONTRANSPARENT_PROXY_STATUS      = "nontransproxy_result"

    //

    let TAG_TASK_NTPTEST = 2001

    //

    let TAG_NTPTEST_REQUEST = -1

    ///
    fileprivate let socketQueue = DispatchQueue(label: "com.specure.rmbt.qos.ntp.socketQueue")

    ///
    fileprivate var ntpTestSocket: GCDAsyncSocket?

    ///
    fileprivate var gotReply = false

    //

    ///
    override init(controlConnection: QOSControlConnection?, delegateQueue: DispatchQueue, testObject: T, speedtestStartTime: UInt64) {
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
            controlConnection?.sendTaskCommand("NTPTEST \(port)", withTimeout: timeoutInSec, forTaskId: testObject.qosTestId, tag: TAG_TASK_NTPTEST)
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

    override func controlConnection(_ connection: QOSControlConnection, didReceiveTaskResponse response: String, withTaskId taskId: UInt, tag: Int) {
        qosLog.debug("CONTROL CONNECTION DELEGATE FOR TASK ID \(taskId), WITH TAG \(tag), WITH STRING \(response)")

        switch tag {
        case TAG_TASK_NTPTEST:
            qosLog.debug("NTPTEST response: \(response)")

            if response.hasPrefix("OK") {

                // create client socket
                ntpTestSocket = GCDAsyncSocket(delegate: self, delegateQueue: delegateQueue, socketQueue: socketQueue)
                ntpTestSocket?.setupSocket()

                // connect client socket
                do {
                    try ntpTestSocket?.connect(toHost: testObject.serverAddress, onPort: testObject.port!, withTimeout: timeoutInSec)
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
    @objc func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        if let socket = ntpTestSocket,
            sock == socket {
            qosLog.debug("will send \(String(describing: testObject.request)) to the server")

            // write request message and read response
            socket.writeLine(line: testObject.request!, withTimeout: timeoutInSec, tag: TAG_NTPTEST_REQUEST) // TODO: what if request is nil?
            socket.readLine(tag: TAG_NTPTEST_REQUEST, withTimeout: timeoutInSec)
        }
    }

    ///
    @objc func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        if sock == ntpTestSocket {
            switch tag {
            case TAG_NTPTEST_REQUEST:

                gotReply = true

                qosLog.debug("\(String(describing: String(data: data, encoding: String.Encoding.ascii)))")

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
    @objc func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        // if (err != nil && err.code == GCDAsyncSocketConnectTimeoutError) { //check for timeout
        //    return testDidTimeout()
        // }
        qosLog.debug("DID DISC gotreply (before?): \(gotReply), error: \(String(describing: err))")
        if !gotReply {
            testDidFail()
        }
    }

}
