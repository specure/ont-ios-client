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
    var delegateQueue: DispatchQueue
    var sendResponse: Bool = false
    var maxPackets: UInt16 = 5
    var timeout: UInt64 = 10_000_000_000
}

///
class UDPStreamReceiver: NSObject {

    ///
    fileprivate let socketQueue = DispatchQueue(label: "com.specure.rmbt.udp.socketQueue")

    ///
    fileprivate var udpSocket: GCDAsyncUdpSocket!

    ///
    fileprivate let countDownLatch = CountDownLatch()

    ///
    // private var running: AtomicBoolean = AtomicBoolean()
    fileprivate var running: Bool = false

    //

    ///
    var delegate: UDPStreamReceiverDelegate?

    ///
    fileprivate let settings: UDPStreamReceiverSettings

    ///
    fileprivate var packetsReceived: UInt16 = 0

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
    fileprivate func connect() {
        Log.logger.debug("connecting udp socket")
        udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: settings.delegateQueue, socketQueue: socketQueue)
        udpSocket.setupSocket()
        do {
            try udpSocket.bind(toPort: settings.port)
            try udpSocket.beginReceiving()
        } catch {
            // TODO: check error (i.e. fail if error)
        }
    }

    ///
    fileprivate func close() {
        Log.logger.debug("closing udp socket")
        udpSocket?.close()
    }

    ///
    fileprivate func receivePacket(_ dataReceived: Data, fromAddress address: Data) { // TODO: use dataReceived
        packetsReceived += 1

        // didReceive callback

        var shouldStop: Bool = false

        settings.delegateQueue.sync {
            shouldStop = self.delegate?.udpStreamReceiver(self, didReceivePacket: dataReceived) ?? false
        }

        if shouldStop || packetsReceived >= settings.maxPackets {
            stop()
        }

        // send response

        if settings.sendResponse {
            var data = NSMutableData()

            var shouldSendResponse: Bool = false

            settings.delegateQueue.sync {
                shouldSendResponse = self.delegate?.udpStreamReceiver(self, willSendPacketWithNumber: self.packetsReceived, data: &data) ?? false
            }

            if shouldSendResponse && data.length > 0 {
                udpSocket.send(data as Data, toAddress: address, withTimeout: nsToSec(settings.timeout), tag: -1) // TODO: TAG
            }
        }
    }

    ///
    func receive() {
        connect()

        running = true

        // TODO: move timeout handling to other class! this class should be more generic!
        _ = countDownLatch.await(settings.timeout) // TODO: timeout
        running = false

        close()
    }

}

// MARK: GCDAsyncUdpSocketDelegate methods

///
extension UDPStreamReceiver: GCDAsyncUdpSocketDelegate {

    ///
    func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        Log.logger.debug("didConnectToAddress: \(address)")
    }

    ///
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        Log.logger.debug("didNotConnect: \(String(describing: error))")
    }

    ///
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        Log.logger.debug("didSendDataWithTag: \(tag)")
    }

    ///
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        Log.logger.debug("didNotSendDataWithTag: \(String(describing: error))")
    }

    ///
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        Log.logger.debug("didReceiveData: \(data)")

        if running {
            receivePacket(data, fromAddress: address)
        }
    }

    ///
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        Log.logger.debug("udpSocketDidClose: \(String(describing: error))")
    }

}
