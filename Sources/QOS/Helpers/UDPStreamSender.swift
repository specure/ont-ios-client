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
    var delegateQueue: DispatchQueue
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
    fileprivate let streamSenderQueue = DispatchQueue(label: "com.specure.rmbt.udp.streamSenderQueue", attributes: DispatchQueue.Attributes.concurrent)

    ///
    fileprivate var udpSocket: GCDAsyncUdpSocket?

    ///
    fileprivate let countDownLatch = CountDownLatch()

    ///
    fileprivate var running = AtomicBoolean()
    fileprivate var isStopped = true

    //

    ///
    weak var delegate: UDPStreamSenderDelegate?

    ///
    fileprivate let settings: UDPStreamSenderSettings

    //

    ///
    fileprivate var packetsReceived: UInt16 = 0

    ///
    fileprivate var packetsSent: UInt16 = 0

    ///
    fileprivate let delayMS: UInt64

    ///
    fileprivate let timeoutMS: UInt64

    ///
    fileprivate let timeoutSec: Double

    ///
    fileprivate var lastSentTimestampMS: UInt64 = 0

    ///
    fileprivate var usleepOverhead: UInt64 = 0

    //

    deinit {
        defer {
            if self.isStopped == false {
                self.stop()
            }
        }
    }
    ///
    required init(settings: UDPStreamSenderSettings) {
        self.settings = settings

        delayMS = settings.delay / NSEC_PER_MSEC
        timeoutMS = settings.timeout / NSEC_PER_MSEC

        timeoutSec = nsToSec(settings.timeout)
    }

    ///
    func stop() {
        _ = running.testAndSet(false)
        close()
    }

    ///
    fileprivate func connect() {
        Log.logger.debug("connecting udp socket")
        stop()
        udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: streamSenderQueue)
        udpSocket?.setupSocket()
        isStopped = false
        //

        do {

            if let portIn = settings.portIn {
                try udpSocket?.bind(toPort: portIn)
            }

            try udpSocket?.connect(toHost: settings.host, onPort: settings.port)

            _ = countDownLatch.await(200 * NSEC_PER_MSEC)

            //

            if !settings.writeOnly {
                try udpSocket?.beginReceiving()
            }
        } catch {
            self.stop()
            Log.logger.debug("bindToPort error?: \(error)")
            Log.logger.debug("connectToHost error?: \(error)") // TODO: check error (i.e. fail if error)
            Log.logger.debug("receive error?: \(error)") // TODO: check error (i.e. fail if error)
        }
    }

    ///
    fileprivate func close() {
        isStopped = true
        Log.logger.debug("closing udp socket")
        udpSocket?.close()//AfterSending()
        udpSocket?.setDelegate(nil)
        udpSocket?.setDelegateQueue(nil)
        udpSocket = nil
    }

    ///
    func send() -> Bool {
        connect()

        let startTimeMS = UInt64.currentTimeMillis()
        let stopTimeMS: UInt64 = (timeoutMS > 0) ? timeoutMS + startTimeMS : 0

        //

        var dataToSend = NSMutableData()
        var shouldSend = false

        //

        var hasTimeout = false

        _ = running.testAndSet(true)

        while (running.boolValue && (self.udpSocket != nil)) {

            ////////////////////////////////////
            // check if should stop

            if stopTimeMS > 0 && stopTimeMS < UInt64.currentTimeMillis() {
                Log.logger.debug("stopping because of stopTimeMS")

                hasTimeout = true
                break
            }

            ////////////////////////////////////
            // check delay

            Log.logger.verbose("currentTimeMS: \(UInt64.currentTimeMillis()), lastSentTimestampMS: \(self.lastSentTimestampMS)")

            var currentDelay = UInt64.currentTimeMillis() - lastSentTimestampMS + usleepOverhead
            Log.logger.verbose("current delay: \(currentDelay)")

            currentDelay = (currentDelay > delayMS) ? 0 : delayMS - currentDelay
            Log.logger.verbose("current delay2: \(currentDelay)")

            if currentDelay > 0 {
                let sleepMicroSeconds = UInt32(currentDelay * 1000)

                let sleepDelay = UInt64.currentTimeMillis()

                usleep(sleepMicroSeconds) // TODO: usleep has an average overhead of about 0-5ms!

                let usleepCurrentOverhead = UInt64.currentTimeMillis() - sleepDelay

                if usleepCurrentOverhead > 20 {
                    usleepOverhead = usleepCurrentOverhead - currentDelay
                } else {
                    usleepOverhead = 0
                }

                Log.logger.verbose("usleep for \(currentDelay)ms took \(usleepCurrentOverhead)ms (overhead \(self.usleepOverhead))")
            }

            ////////////////////////////////////
            // send packet

            if packetsSent < settings.maxPackets {
                dataToSend = NSMutableData()
                
                shouldSend = self.delegate?.udpStreamSender(self, willSendPacketWithNumber: self.packetsSent, data: &dataToSend) ?? false

                if shouldSend {
                    lastSentTimestampMS = UInt64.currentTimeMillis()

                    udpSocket?.send(dataToSend as Data, withTimeout: timeoutSec, tag: Int(packetsSent)) // TAG == packet number

                    packetsSent += 1

                    //lastSentTimestampMS = currentTimeMillis()
                }
            }

            ////////////////////////////////////
            // check for stop

            if settings.writeOnly {
                if packetsSent >= settings.maxPackets {
                    Log.logger.debug("stopping because packetsSent >= settings.maxPackets")
                    break
                }
            } else {
                if packetsSent >= settings.maxPackets && packetsReceived >= settings.maxPackets {
                    Log.logger.debug("stopping because packetsSent >= settings.maxPackets && packetsReceived >= settings.maxPackets")
                    break
                }
            }
        }

        if hasTimeout {
            stop()
        }


        Log.logger.debug("UDP AFTER SEND RETURNS \(!hasTimeout)")

        return !hasTimeout
    }

    ///
    fileprivate func receivePacket(_ dataReceived: Data, fromAddress address: Data) { // TODO: use dataReceived
        if packetsReceived < settings.maxPackets {
            packetsReceived += 1

            // call callback
            settings.delegateQueue.async {
                let _ = self.delegate?.udpStreamSender(self, didReceivePacket: dataReceived)
                return
            }
        }
    }

}

// MARK: GCDAsyncUdpSocketDelegate methods

///
extension UDPStreamSender: GCDAsyncUdpSocketDelegate {

    ///
    func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        Log.logger.debug("didConnectToAddress: address: \(address)")
        Log.logger.debug("didConnectToAddress: local port: \(self.udpSocket?.localPort() ?? 0)")

        settings.delegateQueue.async {
            self.delegate?.udpStreamSender(self, didBindToPort: self.udpSocket?.localPort() ?? 0)
            return
        }

        countDownLatch.countDown()
    }

    ///
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        Log.logger.debug("didNotConnect: \(String(describing: error))")
    }

    ///
    func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        // Log.logger.debug("didSendDataWithTag: \(tag)")
    }

    ///
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        Log.logger.debug("didNotSendDataWithTag: \(String(describing: error))")
    }

    ///
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        // Log.logger.debug("didReceiveData: \(data)")

        // dispatch_async(streamSenderQueue) {
            if self.running.boolValue {
                self.receivePacket(data, fromAddress: address)
            }
        // }
    }

    ///
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) { // crashes if NSError is used without questionmark
        Log.logger.debug("udpSocketDidClose: \(String(describing: error))")
        settings.delegateQueue.async {
            self.delegate?.udpStreamSenderDidClose(self, with: error)
            return
        }
    }

}
