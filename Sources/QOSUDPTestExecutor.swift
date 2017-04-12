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
struct UDPPacketData {

    ///
    var remotePort: UInt16

    ///
    var numPackets: Int // UInt16

    ///
    var dupNumPackets: Int // UInt16

    ///
    var rcvServerResponse: Int = 0

    ///
    init() {
        self.init(remotePort: 0, numPackets: 0, dupNumPackets: 0)
    }

    ///
    init(remotePort: UInt16, numPackets: Int /* UInt16 */, dupNumPackets: Int /* UInt16 */) {
        self.remotePort = remotePort
        self.numPackets = numPackets
        self.dupNumPackets = dupNumPackets
    }
}

///
typealias UDPTestExecutor = QOSUDPTestExecutor<QOSUDPTest>

///
class QOSUDPTestExecutor<T: QOSUDPTest>: QOSTestExecutorClass<T>, UDPStreamSenderDelegate, UDPStreamReceiverDelegate { /*swift compiler segfault if moved to extension*/

    fileprivate let RESULT_UDP_OUTGOING_PACKETS                 = "udp_result_out_num_packets"
    fileprivate let RESULT_UDP_INCOMING_PACKETS                 = "udp_result_in_num_packets"
    fileprivate let RESULT_UDP_OUTGOING_PLR                     = "udp_result_out_packet_loss_rate"
    fileprivate let RESULT_UDP_NUM_PACKETS_OUTGOING_RESPONSE    = "udp_result_out_response_num_packets"
    fileprivate let RESULT_UDP_INCOMING_PLR                     = "udp_result_in_packet_loss_rate"
    fileprivate let RESULT_UDP_NUM_PACKETS_INCOMING_RESPONSE    = "udp_result_in_response_num_packets"
    fileprivate let RESULT_UDP_PORT_OUTGOING                    = "udp_objective_out_port"
    fileprivate let RESULT_UDP_PORT_INCOMING                    = "udp_objective_in_port"
    fileprivate let RESULT_UDP_NUM_PACKETS_OUTGOING             = "udp_objective_out_num_packets"
    fileprivate let RESULT_UDP_NUM_PACKETS_INCOMING             = "udp_objective_in_num_packets"
    fileprivate let RESULT_UDP_DELAY                            = "udp_objective_delay"
    fileprivate let RESULT_UDP_TIMEOUT                          = "udp_objective_timeout"

    //

    /// have to be var to be used in withUsafe*Pointer
    fileprivate var FLAG_UDP_TEST_ONE_DIRECTION: UInt8 = 1
    fileprivate var FLAG_UDP_TEST_RESPONSE: UInt8 = 2
    fileprivate var FLAG_UDP_TEST_AWAIT_RESPONSE: UInt8 = 3

    //

    fileprivate let TAG_TASK_UDPTEST_OUT = 3001
    fileprivate let TAG_TASK_GET_UDPPORT = 3002
    fileprivate let TAG_TASK_UDPTEST_IN = 3003
    fileprivate let TAG_TASK_UDPRESULT_OUT = 3004

    //

    ///
    fileprivate var udpStreamSender: UDPStreamSender!

    ///
    fileprivate var udpStreamReceiver: UDPStreamReceiver!

    //
    fileprivate var packetsReceived = [UInt8]()
    fileprivate var packetsDuplicate = [UInt8]()

    fileprivate var resultPacketData = UDPPacketData()

    //

    ///
    override init(controlConnection: QOSControlConnection, delegateQueue: DispatchQueue, testObject: T, speedtestStartTime: UInt64) {
        super.init(controlConnection: controlConnection, delegateQueue: delegateQueue, testObject: testObject, speedtestStartTime: speedtestStartTime)
    }

    ///
    override func startTest() {
        super.startTest()

        testResult.set(RESULT_UDP_DELAY, number: testObject.delay)
        testResult.set(RESULT_UDP_TIMEOUT, number: testObject.timeout)
    }

    ///
    override func endTest() {
        super.endTest()

        udpStreamSender?.stop()
        udpStreamReceiver?.stop()
    }

    ///
    override func executeTest() {
        qosLog.debug("EXECUTING UDP TEST")

        // outgoing
        if let packetCountOut = testObject.packetCountOut {
            if let portOut = testObject.portOut {

                announceOutgoingTest(portOut, packetCountOut)
            } else {

                // ask for port
                controlConnection.sendTaskCommand("GET UDPPORT", withTimeout: timeoutInSec, forTaskId: testObject.qosTestId, tag: TAG_TASK_GET_UDPPORT)
            }
        }

        // incoming
        if let packetCountIn = testObject.packetCountIn, let portIn = testObject.portIn {
            announceIncomingTest(portIn, packetCountIn)
        }

        // check if both params aren't set
        if testObject.packetCountOut == nil && testObject.packetCountIn == nil {
            testResult.set(RESULT_UDP_NUM_PACKETS_OUTGOING_RESPONSE, value: "NOT_SET" as AnyObject?)
            testResult.set(RESULT_UDP_NUM_PACKETS_INCOMING_RESPONSE, value: "NOT_SET" as AnyObject?)

            callFinishCallback()
        }
    }

    ///
    override func testDidSucceed() {
        super.testDidSucceed()
    }

    ///
    override func testDidTimeout() {
        // testResult.set(RESULT_UDP_TIMEOUT, value: "")

        super.testDidTimeout()
    }

    ///
    override func testDidFail() {
        super.testDidFail()
    }

// MARK: test methods

    ///
    fileprivate func announceOutgoingTest(_ portOut: UInt16, _ packetCountOut: UInt16) {
        qosLog.debug("announceOutgoingTest \(portOut), \(packetCountOut)")

        testResult.set(RESULT_UDP_NUM_PACKETS_OUTGOING, number: testObject.packetCountOut!)
        testResult.set(RESULT_UDP_PORT_OUTGOING,        number: testObject.portOut!)

        controlConnection.sendTaskCommand("UDPTEST OUT \(portOut) \(packetCountOut)", withTimeout: timeoutInSec, forTaskId: testObject.qosTestId, tag: TAG_TASK_UDPTEST_OUT)
    }

    ///
    fileprivate func announceIncomingTest(_ portIn: UInt16, _ packetCountIn: UInt16) {
        qosLog.debug("announceIncomingTest \(portIn), \(packetCountIn)")

        testResult.set(RESULT_UDP_NUM_PACKETS_INCOMING, number: testObject.packetCountIn!)
        testResult.set(RESULT_UDP_PORT_INCOMING,        number: testObject.portIn!)

        controlConnection.sendTaskCommand("UDPTEST IN \(portIn) \(packetCountIn)", withTimeout: timeoutInSec, forTaskId: testObject.qosTestId, tag: TAG_TASK_UDPTEST_IN)
    }

    ///
    fileprivate func startOutgoingTest() {
        let settings = UDPStreamSenderSettings(
            host: testObject.serverAddress,
            port: testObject.portOut!,
            delegateQueue: delegateQueue,
            sendResponse: true,
            maxPackets: testObject.packetCountOut!,
            timeout: testObject.timeout,
            delay: testObject.delay,
            writeOnly: false,
            portIn: nil
        )

        udpStreamSender = UDPStreamSender(settings: settings)
        udpStreamSender.delegate = self

        qosLog.debug("before send udpStreamSender")

        let boolOk = udpStreamSender.send()

        qosLog.debug("after send udpStreamSender (\(boolOk))")

        if !boolOk {
            testDidTimeout()
            return
        }

        // request results
        // wait short time (last udp packet could reach destination after this request resulting in strange server behaviour)
        usleep(100000) /* 100 * 1000 */
        controlConnection.sendTaskCommand("GET UDPRESULT OUT \(testObject.portOut!)", withTimeout: timeoutInSec, forTaskId: testObject.qosTestId, tag: TAG_TASK_UDPRESULT_OUT)
    }

    ///
    fileprivate func finishOutgoingTest() {
        testResult.set(RESULT_UDP_OUTGOING_PACKETS,                 value: resultPacketData.rcvServerResponse as AnyObject?)
        testResult.set(RESULT_UDP_NUM_PACKETS_OUTGOING_RESPONSE,    value: resultPacketData.numPackets as AnyObject?)

        // calculate packet loss rate
        let lostPackets = Int(testObject.packetCountOut!) - resultPacketData.numPackets

        qosLog.debug("UDP Outgoing, all: \(resultPacketData.numPackets), lost: \(lostPackets)")

        if lostPackets > 0 {

            let packetLossRate = Double(lostPackets) / Double(testObject.packetCountOut!) * 100
            qosLog.debug("packet loss rate: \(packetLossRate)")

            testResult.set(RESULT_UDP_OUTGOING_PLR, value: "\(packetLossRate)" as AnyObject?)

        } else {
            testResult.set(RESULT_UDP_OUTGOING_PLR, value: "0" as AnyObject?)
        }

        // TODO: call finish callback only when both incoming and outgoing are finished
        testDidSucceed()
    }

    ///
    fileprivate func startIncomingTest() {
        let settings = UDPStreamReceiverSettings(
            port: testObject.portIn!,
            delegateQueue: delegateQueue,
            sendResponse: true,
            maxPackets: testObject.packetCountIn!,
            timeout: testObject.timeout
        )

        udpStreamReceiver = UDPStreamReceiver(settings: settings)
        udpStreamReceiver.delegate = self

        qosLog.debug("before receive udpStreamReceiver")

        udpStreamReceiver.receive()

        qosLog.debug("after receive udpStreamReceiver")
    }

    ///
    fileprivate func finishIncomingTest() {
        // TODO
    }

// MARK: QOSControlConnectionDelegate methods

    ///
    override func controlConnection(_ connection: QOSControlConnection, didReceiveTaskResponse response: String, withTaskId taskId: UInt, tag: Int) {
        qosLog.debug("CONTROL CONNECTION DELEGATE FOR TASK ID \(taskId), WITH TAG \(tag), WITH STRING \(response)")

        switch tag {
            case TAG_TASK_UDPTEST_OUT:
                qosLog.debug("TAG_TASK_UDPTEST_OUT response: \(response)")

                if response.hasPrefix("OK") {
                    // send udp packets
                    qosLog.debug("send udp packets")

                    // send udp packets
                    startOutgoingTest()

                    // callFinishCallback()
                } else {
                    testDidFail()
                    // failTestWithFatalError() // TODO: stop tests and close sockets etc. ... // TODO: or just run in timeout?
                }

            case TAG_TASK_GET_UDPPORT:
                qosLog.debug("TAG_TASK_GET_UDPPORT response: \(response)")

                if !response.hasPrefix("ERR") {
                    if let portOut = Int(response) {
                        announceOutgoingTest(UInt16(portOut), testObject.packetCountOut!)
                    } else {
                        // TODO: fail
                        testDidFail()
                        // failTestWithFatalError() // TODO: stop tests and close sockets etc. ... // TODO: or just run in timeout?
                    }
                } else {
                    // TODO: fail
                    testDidFail()
                    // failTestWithFatalError() // TODO: stop tests and close sockets etc. ... // TODO: or just run in timeout?
                }

            case TAG_TASK_UDPTEST_IN:
                qosLog.debug("TAG_TASK_UDPTEST_IN response: \(response)")

            case TAG_TASK_UDPRESULT_OUT:
                qosLog.debug("TAG_TASK_UDPRESULT_OUT response: \(response)")

                if response.hasPrefix("RCV") {
                    qosLog.debug("got RCV")

                    // TODO: with regex?
                    let rcvArray: [String] = response.components(separatedBy: " ")

                    if rcvArray.count > 1 {
                        if let rcvss = Int(rcvArray[1]) {
                            resultPacketData.rcvServerResponse = rcvss
                        }
                    }
                }

                finishOutgoingTest()

            default:
                // do nothing
                qosLog.debug("default case: do nothing")
        }
    }

    ///
    /* override func controlConnection(connection: QOSControlConnection, didReceiveTimeout elapsed: NSTimeInterval, withTaskId taskId: UInt, tag: Int) {
        // let test fail/timeout
    } */

    ///
    fileprivate func appendPacketData(_ data: inout NSMutableData, flag: UInt8, packetNumber: UInt16) {

        // write flag
        data.appendValue(flag)

        // write packetNumber
        data.appendValue(UInt8(packetNumber)) // make sure only 1 byte is used for packageNumber here

        // write uuid
        assert(testToken != nil, "testToken must not be nil")
        let uuid = testToken.components(separatedBy: "_")[0] // split uuid from testToken
        data.append(uuid.data(using: String.Encoding.ascii)!)

        // write current time
        let ctm = "\(currentTimeMillis())"
        data.append(ctm.data(using: String.Encoding.ascii)!)
    }

// MARK: UDPStreamSenderDelegate methods

    /// returns false if the class should stop
    func udpStreamSender(_ udpStreamSender: UDPStreamSender, didReceivePacket packetData: Data) -> Bool {
        qosLog.debug("udpStreamSenderDidReceive: \(packetData)")

        var flag: UInt8 = 0
        (packetData as NSData).getBytes(&flag, length: MemoryLayout<UInt8>.size)

        var packetNumber: UInt8 = 0
        (packetData as NSData).getBytes(&packetNumber, range: NSRange(location: 1, length: 1))

        if flag != FLAG_UDP_TEST_RESPONSE {
            qosLog.error("BAD UDP IN TEST PACKET IDENTIFIER")
            return false // TODO ???
        }

        if packetsReceived.contains(packetNumber) {
            packetsDuplicate.append(packetNumber)

            qosLog.error("DUPLICATE UDP IN TEST PACKET ID")

            // if (false/*ABORT_ON_DUPLICATE_UDP_PACKETS*/) {
            //    return false // TODO ???
            // }
        } else {
            packetsReceived.append(packetNumber)
        }

        resultPacketData.numPackets = packetsReceived.count
        resultPacketData.dupNumPackets = packetsDuplicate.count

        return true
    }

    /// returns false if the class should stop
    func udpStreamSender(_ udpStreamSender: UDPStreamSender, willSendPacketWithNumber packetNumber: UInt16, data: inout NSMutableData) -> Bool {
        qosLog.debug("udpStreamSenderwillSendPacketWithNumber: \(packetNumber)")

        appendPacketData(&data, flag: FLAG_UDP_TEST_AWAIT_RESPONSE, packetNumber: packetNumber)

        return true
    }

    ///
    func udpStreamSender(_ udpStreamSender: UDPStreamSender, didBindToPort port: UInt16) {
        // do nothing
    }

// MARK: UDPStreamReceiverDelegate methods

    ///
    func udpStreamReceiver(_ udpStreamReceiver: UDPStreamReceiver, didReceivePacket packetData: Data) -> Bool {
        qosLog.debug("udpStreamReceiverDidReceive: \(packetData)")

        // TODO

        return true
    }

    ///
    func udpStreamReceiver(_ udpStreamReceiver: UDPStreamReceiver, willSendPacketWithNumber packetNumber: UInt16, data: inout NSMutableData) -> Bool {
        qosLog.debug("udpStreamReceiverwillSendPacketWithNumber: \(packetNumber)")

        appendPacketData(&data, flag: FLAG_UDP_TEST_RESPONSE, packetNumber: packetNumber)

        return true
    }

}
