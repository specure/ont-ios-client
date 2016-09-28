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
struct UDPStreamSenderSettings {
    var host: String
    var port: UInt16 = 0
    var delegateQueue: dispatch_queue_t
    var sendResponse: Bool = false
    var maxPackets: UInt16 = 5
    var timeout: UInt64 = 10_000_000_000
    var delay: UInt64 = 10_000
    var writeOnly: Bool = false
    var portIn: UInt16?
}

///
class UDPStreamSender: NSObject {

    ///
    private let streamSenderQueue = dispatch_queue_create("com.specure.rmbt.udp.streamSenderQueue", DISPATCH_QUEUE_CONCURRENT)

    ///
    private var udpSocket: GCDAsyncUdpSocket!

    ///
    private let countDownLatch = CountDownLatch()

    ///
    private var running = AtomicBoolean()

    //

    ///
    var delegate: UDPStreamSenderDelegate?

    ///
    private let settings: UDPStreamSenderSettings

    //

    ///
    private var packetsReceived: UInt16 = 0

    ///
    private var packetsSent: UInt16 = 0

    ///
    private let delayMS: UInt64

    ///
    private let timeoutMS: UInt64

    ///
    private let timeoutSec: Double

    ///
    private var lastSentTimestampMS: UInt64 = 0

    ///
    private var usleepOverhead: UInt64 = 0

    //

    ///
    required init(settings: UDPStreamSenderSettings) {
        self.settings = settings

        delayMS = settings.delay / NSEC_PER_MSEC
        timeoutMS = settings.timeout / NSEC_PER_MSEC

        timeoutSec = nsToSec(settings.timeout)
    }

    ///
    func stop() {
        running.testAndSet(false)
    }

    ///
    private func connect() {
        logger.debug("connecting udp socket")
        udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: streamSenderQueue)

        //

        do {

            if let portIn = settings.portIn {
                try udpSocket.bindToPort(portIn)
            }

            try udpSocket.connectToHost(settings.host, onPort: settings.port)

            countDownLatch.await(200 * NSEC_PER_MSEC)

            //

            if !settings.writeOnly {
                try udpSocket.beginReceiving()
            }
        } catch {
            logger.debug("bindToPort error?: \(error)")
            logger.debug("connectToHost error?: \(error)") // TODO: check error (i.e. fail if error)
            logger.debug("receive error?: \(error)") // TODO: check error (i.e. fail if error)
        }
    }

    ///
    private func close() {
        logger.debug("closing udp socket")
        udpSocket?.closeAfterSending()
    }

    ///
    func send() -> Bool {
        connect()

        let startTimeMS = currentTimeMillis()
        let stopTimeMS: UInt64 = (timeoutMS > 0) ? timeoutMS + startTimeMS : 0

        //

        var dataToSend = NSMutableData()
        var shouldSend = false

        //

        var hasTimeout = false

        running.testAndSet(true)

        while running {

            ////////////////////////////////////
            // check if should stop

            if stopTimeMS > 0 && stopTimeMS < currentTimeMillis() {
                logger.debug("stopping because of stopTimeMS")

                hasTimeout = true
                break
            }

            ////////////////////////////////////
            // check delay

            logger.verbose("currentTimeMS: \(currentTimeMillis()), lastSentTimestampMS: \(lastSentTimestampMS)")

            var currentDelay = currentTimeMillis() - lastSentTimestampMS + usleepOverhead
            logger.verbose("current delay: \(currentDelay)")

            currentDelay = (currentDelay > delayMS) ? 0 : delayMS - currentDelay
            logger.verbose("current delay2: \(currentDelay)")

            if currentDelay > 0 {
                let sleepMicroSeconds = UInt32(currentDelay * 1000)

                let sleepDelay = currentTimeMillis()

                usleep(sleepMicroSeconds) // TODO: usleep has an average overhead of about 0-5ms!

                let usleepCurrentOverhead = currentTimeMillis() - sleepDelay

                if usleepCurrentOverhead > 20 {
                    usleepOverhead = usleepCurrentOverhead - currentDelay
                } else {
                    usleepOverhead = 0
                }

                logger.verbose("usleep for \(currentDelay)ms took \(usleepCurrentOverhead)ms (overhead \(usleepOverhead))")
            }

            ////////////////////////////////////
            // send packet

            if packetsSent < settings.maxPackets {
                dataToSend.length = 0

                shouldSend = self.delegate?.udpStreamSender(self, willSendPacketWithNumber: self.packetsSent, data: &dataToSend) ?? false

                if shouldSend {
                    lastSentTimestampMS = currentTimeMillis()

                    udpSocket.sendData(dataToSend, withTimeout: timeoutSec, tag: Int(packetsSent)) // TAG == packet number

                    packetsSent += 1

                    //lastSentTimestampMS = currentTimeMillis()
                }
            }

            ////////////////////////////////////
            // check for stop

            if settings.writeOnly {
                if packetsSent >= settings.maxPackets {
                    logger.debug("stopping because packetsSent >= settings.maxPackets")
                    break
                }
            } else {
                if packetsSent >= settings.maxPackets && packetsReceived >= settings.maxPackets {
                    logger.debug("stopping because packetsSent >= settings.maxPackets && packetsReceived >= settings.maxPackets")
                    break
                }
            }
        }

        stop()
        close()

        logger.debug("UDP AFTER SEND RETURNS \(!hasTimeout)")

        return !hasTimeout
    }

    ///
    private func receivePacket(dataReceived: NSData, fromAddress address: NSData) { // TODO: use dataReceived
        if packetsReceived < settings.maxPackets {
            packetsReceived += 1

            // call callback
            dispatch_async(settings.delegateQueue) {
                self.delegate?.udpStreamSender(self, didReceivePacket: dataReceived)
                return
            }
        }
    }

}

// MARK: GCDAsyncUdpSocketDelegate methods

///
extension UDPStreamSender: GCDAsyncUdpSocketDelegate {

    ///
    func udpSocket(sock: GCDAsyncUdpSocket, didConnectToAddress address: NSData) {
        logger.debug("didConnectToAddress: address: \(address)")
        logger.debug("didConnectToAddress: local port: \(udpSocket.localPort())")

        dispatch_async(settings.delegateQueue) {
            self.delegate?.udpStreamSender(self, didBindToPort: self.udpSocket.localPort())
            return
        }

        countDownLatch.countDown()
    }

    ///
    func udpSocket(sock: GCDAsyncUdpSocket, didNotConnect error: NSError?) {
        logger.debug("didNotConnect: \(error)")
    }

    ///
    func udpSocket(sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        // logger.debug("didSendDataWithTag: \(tag)")
    }

    ///
    func udpSocket(sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: NSError?) {
        logger.debug("didNotSendDataWithTag: \(error)")
    }

    ///
    func udpSocket(sock: GCDAsyncUdpSocket, didReceiveData data: NSData, fromAddress address: NSData, withFilterContext filterContext: AnyObject?) {
        // logger.debug("didReceiveData: \(data)")

        // dispatch_async(streamSenderQueue) {
            if self.running {
                self.receivePacket(data, fromAddress: address)
            }
        // }
    }

    ///
    func udpSocketDidClose(sock: GCDAsyncUdpSocket, withError error: NSError?) { // crashes if NSError is used without questionmark
        logger.debug("udpSocketDidClose: \(error)")
    }

}
