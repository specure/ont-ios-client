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
struct UDPStreamReceiverSettings {
    var port: UInt16 = 0
    var delegateQueue: dispatch_queue_t
    var sendResponse: Bool = false
    var maxPackets: UInt16 = 5
    var timeout: UInt64 = 10_000_000_000
}

///
class UDPStreamReceiver: NSObject {

    ///
    private let socketQueue = dispatch_queue_create("com.specure.rmbt.udp.socketQueue", DISPATCH_QUEUE_CONCURRENT)

    ///
    private var udpSocket: GCDAsyncUdpSocket!

    ///
    private let countDownLatch = CountDownLatch()

    ///
    // private var running: AtomicBoolean = AtomicBoolean()
    private var running: Bool = false

    //

    ///
    var delegate: UDPStreamReceiverDelegate?

    ///
    private let settings: UDPStreamReceiverSettings

    ///
    private var packetsReceived: UInt16 = 0

    //

    ///
    required init(settings: UDPStreamReceiverSettings) {
        self.settings = settings
    }

    ///
    func stop() {
        countDownLatch.countDown()
    }

    ///
    private func connect() {
        logger.debug("connecting udp socket")
        udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: settings.delegateQueue, socketQueue: socketQueue)

        do {
            try udpSocket.bindToPort(settings.port)
            try udpSocket.beginReceiving()
        } catch {
            // TODO: check error (i.e. fail if error)
        }
    }

    ///
    private func close() {
        logger.debug("closing udp socket")
        udpSocket?.close()
    }

    ///
    private func receivePacket(dataReceived: NSData, fromAddress address: NSData) { // TODO: use dataReceived
        packetsReceived += 1

        // didReceive callback

        var shouldStop: Bool = false

        dispatch_sync(settings.delegateQueue) {
            shouldStop = self.delegate?.udpStreamReceiver(self, didReceivePacket: dataReceived) ?? false
        }

        if shouldStop || packetsReceived >= settings.maxPackets {
            stop()
        }

        // send response

        if settings.sendResponse {
            var data = NSMutableData()

            var shouldSendResponse: Bool = false

            dispatch_sync(settings.delegateQueue) {
                shouldSendResponse = self.delegate?.udpStreamReceiver(self, willSendPacketWithNumber: self.packetsReceived, data: &data) ?? false
            }

            if shouldSendResponse && data.length > 0 {
                udpSocket.sendData(data, toAddress: address, withTimeout: nsToSec(settings.timeout), tag: -1) // TODO: TAG
            }
        }
    }

    ///
    func receive() {
        connect()

        running = true

        // TODO: move timeout handling to other class! this class should be more generic!
        countDownLatch.await(settings.timeout) // TODO: timeout
        running = false

        close()
    }

}

// MARK: GCDAsyncUdpSocketDelegate methods

///
extension UDPStreamReceiver: GCDAsyncUdpSocketDelegate {

    ///
    func udpSocket(sock: GCDAsyncUdpSocket, didConnectToAddress address: NSData) {
        logger.debug("didConnectToAddress: \(address)")
    }

    ///
    func udpSocket(sock: GCDAsyncUdpSocket, didNotConnect error: NSError?) {
        logger.debug("didNotConnect: \(error)")
    }

    ///
    func udpSocket(sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        logger.debug("didSendDataWithTag: \(tag)")
    }

    ///
    func udpSocket(sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: NSError?) {
        logger.debug("didNotSendDataWithTag: \(error)")
    }

    ///
    func udpSocket(sock: GCDAsyncUdpSocket, didReceiveData data: NSData, fromAddress address: NSData, withFilterContext filterContext: AnyObject?) {
        logger.debug("didReceiveData: \(data)")

        if running {
            receivePacket(data, fromAddress: address)
        }
    }

    ///
    func udpSocketDidClose(sock: GCDAsyncUdpSocket, withError error: NSError?) {
        logger.debug("udpSocketDidClose: \(error)")
    }

}
