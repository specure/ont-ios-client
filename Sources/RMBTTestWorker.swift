/*****************************************************************************************************
 * Copyright 2013 appscape gmbh
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
public enum RMBTTestWorkerState: Int {
    case initialized

    case downlinkPretestStarted
    case downlinkPretestFinished

    case latencyTestStarted
    case latencyTestFinished

    case downlinkTestStarted
    case downlinkTestFinished

    case uplinkPretestStarted
    case uplinkPretestFinished

    case uplinkTestStarted
    case uplinkTestFinished

    case stopping
    case stopped

    case aborted
    case failed
}

/// We use long to be compatible with GCDAsyncSocket tag datatype
public enum RMBTTestTag: Int {
    case rxPretestPart = -2
    case rxDownlinkPart = -1

    case rxBanner = 1
    case rxBannerAccept
    case txToken
    case rxTokenOK
    case rxChunksize
    case rxChunksizeAccept
    case txGetChunks
    case rxChunk
    case txChunkOK
    case rxStatistic
    case rxStatisticAccept
    case txPing
    case rxPong
    case txPongOK
    case rxPongStatistic
    case rxPongAccept
    case txGetTime
    case rxGetTime
    case rxGetTimeLeftoverChunk
    case txGetTimeOK
    case rxGetTimeStatistic
    case rxGetTimeAccept
    case txQuit
    case txPutNoResult
    case rxPutNoResultOK
    case txPutNoResultChunk
    case rxPutNoResultStatistic
    case rxPutNoResultAccept
    case txPut
    case rxPutOK
    case txPutChunk
    case rxPutStatistic
    case rxPutStatisticLast
}

/// All delegate methods are dispatched on the supplied delegate queue
@objc public protocol RMBTTestWorkerDelegate: AnyObject {

    ///
    
    @objc optional func testWorker(_ worker: RMBTTestWorker, didFinishDownlinkPretestWithChunkCount chunks: UInt, withTime duration: UInt64)

    ///
    @objc optional func testWorker(_ worker: RMBTTestWorker, didMeasureLatencyWithServerNanos serverNanos: UInt64, clientNanos: UInt64)

    ///
    func testWorker(_ worker: RMBTTestWorker, startPing: Int, totalPings: Int)
    
    ///
    @objc optional func testWorkerDidFinishLatencyTest(_ worker: RMBTTestWorker)

    ///
    func testWorker(_ worker: RMBTTestWorker, didStartDownlinkTestAtNanos nanos: UInt64) -> UInt64

    ///
    func testWorker(_ worker: RMBTTestWorker, didDownloadLength length: UInt64, atNanos nanos: UInt64)

    ///
    func testWorkerDidFinishDownlinkTest(_ worker: RMBTTestWorker)

    ///
    func testWorker(_ worker: RMBTTestWorker, didFinishUplinkPretestWithChunkCount chunks: UInt)

    ///
    func testWorker(_ worker: RMBTTestWorker, didStartUplinkTestAtNanos nanos: UInt64) -> UInt64

    ///
    func testWorker(_ worker: RMBTTestWorker, didUploadLength length: UInt64, atNanos nanos: UInt64)

    ///
    func testWorkerDidFinishUplinkTest(_ worker: RMBTTestWorker)

    ///
    func testWorkerDidStop(_ worker: RMBTTestWorker)

    ///
    func testWorkerDidFail(_ worker: RMBTTestWorker)
}

///
open class RMBTTestWorker: NSObject, GCDAsyncSocketDelegate {

    // Test parameters
    private var params: SpeedMeasurementResponse

    /// Weak reference to the delegate
    private weak var delegate: RMBTTestWorkerDelegate?

    /// Current state of the worker
    private var state: RMBTTestWorkerState = .initialized

    ///
    private var socket: GCDAsyncSocket!

    /// CHUNKSIZE received from server
    private var chunksize: UInt = 0

    /// One chunk of data cached from the downlink phase, to be used as upload data
    private var chunkData: Data!

    /// In pretest, we first request or send 1 chunk at once, then 2, 4, 8 etc.
    /// Number of chunks to request/send in this iteration
    private var pretestChunksCount: UInt = 0

    /// Uplink pretest: number of chunks sent so far in this iteration
    private var pretestChunksSent: UInt = 0

    /// Download pretest: length received so far
    private var pretestLengthReceived: UInt64 = 0

    /// Nanoseconds at which we started pretest
    private var pretestStartNanos: UInt64 = 0

    /// Nanoseconds at which we sent the PING
    private var pingStartNanos: UInt64 = 0

    /// Nanoseconds at which we received PONG
    private var pingPongNanos: UInt64 = 0

    /// Current ping sequence number (0.._params.pingCount-1)
    private var pingSeq: UInt = 0

    /// Nanoseconds at which test started. Used for both up/down tests.
    private var testStartNanos: UInt64 = 0

    /// Download buffer for capturing bytes for _chunkData
    private var testDownloadedData: Data!

    /// How many nanoseconds is this thread behind the first thread that started upload test
    private var testUploadOffsetNanos: UInt64 = 0

    /// Local timestamps after which we'll start discarding server reports and finalize the upload test
    private var testUploadEnoughClientNanos: UInt64 = 0
    private var testUploadMaxWaitReachedClientNanos: UInt64 = 0

    // Server timestamp after which it is considered that we have enough upload
    private var testUploadEnoughServerNanos: UInt64 = 0

    /// Flag indicating that last uplink packet has been sent. After last chunk has been sent, we'll wait upto X sec to
    /// collect statistics, then terminate the test.
    private var testUploadLastChunkSent = false

    /// Server reports total number of bytes received. We need to track last amount reported so we can calculate relative amounts.
    private var testUploadLastUploadLength: UInt64 = 0

    ///
    open var index: UInt

    ///
    open var totalBytesUploaded: UInt64 = 0

    ///
    open var totalBytesDownloaded: UInt64 = 0

    ///
    open var negotiatedEncryptionString: String!

    ///
    open var localIp: String!

    ///
    open var serverIp: String!
    
    private var downlinkPretestCompleteHandler: (_ chunks: UInt64, _ duration: UInt64) -> Void = { _, _ in }
    private var latencyProgressHandler: (_ percent: Float, _ serverNanos: UInt64, _ clientNanos: UInt64) -> Void = { _, _, _ in }
    private var latencyCompleteHandler: () -> Void = { }

    ///
    //private let serverConnectionFailedTimer = GCDTimer()

    ///
    public init(delegate: RMBTTestWorkerDelegate, delegateQueue: DispatchQueue, index: UInt, testParams: SpeedMeasurementResponse) {
        self.delegate = delegate
        self.index = index
        self.params = testParams
        //self.state = .Initialized

        super.init()

        socket = GCDAsyncSocket(delegate: self, delegateQueue: delegateQueue)
        socket.setupSocket()
    }

// MARK: State handling

    ///
    @objc open func startDownlinkPretest(complete: @escaping (_ chunks: UInt64, _ duration: UInt64) -> Void = {_,_ in }) {
        if state != .aborted && state != .failed {
            assert(state == .initialized, "Invalid state")
            
            self.downlinkPretestCompleteHandler = complete
            state = .downlinkPretestStarted
            
            connect()
        }
    }

    ///
    open func stop() {
        assert(state == .downlinkPretestFinished, "Invalid state")

        state = .stopping

        socket.disconnect()
    }

    ///
    @objc open func startLatencyTest(progress: @escaping (_ percent: Float, _ serverNanos: UInt64, _ clientNanos: UInt64) -> Void, complete: @escaping () -> Void) {
        assert(state == .downlinkPretestFinished, "Invalid state")

        state = .latencyTestStarted
        
        self.latencyProgressHandler = progress
        self.latencyCompleteHandler = complete
        
        pingSeq = 0
        writeLine("PING", withTag: .txPing)

        pingStartNanos = RMBTCurrentNanos()
    }

    ///
    @objc open func startDownlinkTest() {
        if state != .aborted {
            assert(state == .latencyTestFinished || state == .downlinkPretestFinished, "Invalid state")

            state = .downlinkTestStarted

            writeLine("GETTIME \(Int(params.duration))", withTag: .txGetTime)
        }
    }

    ///
    @objc open func startUplinkPretest() {
        assert(state == .downlinkTestFinished, "Invalid state")

        state = .uplinkPretestStarted

        connect()
    }

    ///
    @objc open func startUplinkTest() {
        assert(state == .uplinkPretestFinished, "Invalid state")

        state = .uplinkTestStarted

        writeLine("PUT", withTag: .txPut)
    }

// MARK: ...

    private func tryDNSLookup(_ serverName: String) -> String? {
        let host = CFHostCreateWithName(nil, serverName as CFString).takeRetainedValue()
        CFHostStartInfoResolution(host, .addresses, nil)
        var success: DarwinBoolean = false
        if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray?, let theAddress = addresses.firstObject as? Data {
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if getnameinfo((theAddress as NSData).bytes.bindMemory(to: sockaddr.self, capacity: theAddress.count), socklen_t(theAddress.count),
                    &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                        if let numAddress = String(validatingUTF8: hostname) {
                            return numAddress
                        }
                }
        }

        return nil
    }

    ///
    open func connect() {
        do {
            //setupConnectionFailedTimer()

            // iOS 9: fails with socketDidDisconnect(_:withError:) > Socket disconnected with error Error Domain=kCFStreamErrorDomainNetDB Code=8
            // "nodename nor servname provided, or not known" UserInfo={NSLocalizedDescription=nodename nor servname provided, or not known}

            // try dns lookup first as a workaround for the ios 9 bug
            var sAddr = params.measurementServer?.address ?? "" // TODO
            if let ip = tryDNSLookup(sAddr) {
                sAddr = ip
            }

            if let port = self.params.measurementServer?.port {
                Log.logger.debug("Connecting to host \(sAddr):\(port)")
                try socket.connect(toHost: sAddr, onPort: UInt16(port) /*TODO*/, withTimeout: RMBT_TEST_SOCKET_TIMEOUT_S)
            }
            else {
                Log.logger.error("Connecting to host: Unknowed port and maybe host")
                fail()
            }
        } catch {
            fail()
        }
    }

    ///
    /*private func setupConnectionFailedTimer() {
        serverConnectionFailedTimer.interval = 5 // fail after 5 seconds if no connection can be established
        serverConnectionFailedTimer.timerCallback = {
            Log.logger.debug("CONNECTION TIMER FIRED!")
            self.fail()
        }
        serverConnectionFailedTimer.start()
    }*/

    ///
    open func abort() {
        if state == .aborted {
            return
        }

        //serverConnectionFailedTimer.stop()
        state = .aborted

        if socket.isConnected {
            socket.disconnect()
        }
    }

    ///
    open func fail() {
        if state == .failed {
            return
        }

        //serverConnectionFailedTimer.stop()
        state = .failed

        delegate?.testWorkerDidFail(self)

        if socket.isConnected {
            socket.disconnect()
        }
    }

// MARK: Socket delegate methods

    ///
    open func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        if state == .aborted {
            sock.disconnect()
            return
        }

        assert(state == .downlinkPretestStarted || state == .uplinkPretestStarted, "Invalid state")

        localIp = sock.localHost
        serverIp = sock.connectedHost

        if let ms = params.measurementServer, ms.encrypted { // TODO
            sock.startTLS([
                GCDAsyncSocketManuallyEvaluateTrust: true as NSObject
            ])
        } else {
            readLineWithTag(.rxBanner)
        }
    }

    ///
    open func socket(_ sock: GCDAsyncSocket, didReceive trust: SecTrust, completionHandler: @escaping ((Bool) -> Void)) {
        completionHandler(true)
    }

    ///
    open func socketDidSecure(_ sock: GCDAsyncSocket) {
        assert(state == .downlinkPretestStarted || state == .uplinkPretestStarted, "Invalid state")

        socket.perform {
            if let sslContext = sock.sslContext() {
                self.negotiatedEncryptionString = RMBTSSLHelper.encryptionStringForSSLContext(sslContext.takeUnretainedValue()) // TODO: or use takeRetainedValue()?
            }
        }

        readLineWithTag(.rxBanner)
    }

    ///
    open func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        if err != nil {
            Log.logger.debug("Socket disconnected with error \(String(describing: err))")
            fail()
        } else {
            if state == .downlinkTestStarted {
                state = .downlinkTestFinished
                delegate?.testWorkerDidFinishDownlinkTest(self)
            } else if state == .stopping {
                state = .stopped
                delegate?.testWorkerDidStop(self)
            } else if state == .failed || state == .aborted || state == .uplinkTestFinished {
                // We've finished/aborted/failed and socket has disconnected. Nothing to do!
            } else {
                assert(false, "Disconnection in an unexpected state")
            }
        }
    }

    ///
    open func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        if state == .aborted {
            return
        }

        socketDidReadOrWriteData(nil, withTag: tag, read: false)
    }

    ///
    open func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        if state == .aborted {
            return
        }

        totalBytesDownloaded += UInt64(data.count)

        socketDidReadOrWriteData(data, withTag: tag, read: true)
    }

    /// We unify read and write callbacks for better state documentation
    open func socketDidReadOrWriteData(_ data: Data!, withTag tagRaw: Int, read: Bool) {
        let tag = RMBTTestTag(rawValue: tagRaw)!

        // Pretest
        if tag == .rxBanner {
            // <- RMBTv0.3
            readLineWithTag(.rxBannerAccept)
        } else if tag == .rxBannerAccept {
            // <- ACCEPT
            writeLine("TOKEN \(params.testToken!)", withTag: .txToken) // TODO: optionals!!!
        } else if tag == .txToken {
            // -> TOKEN ...
            readLineWithTag(.rxTokenOK)
        } else if tag == .rxTokenOK {
            // <- OK
            readLineWithTag(.rxChunksize)
        } else if tag == .rxChunksize {
            // got chunksize -> server should work, now connection failed timer can be stopped
            //serverConnectionFailedTimer.stop()
            //

            // <- CHUNKSIZE

            let line = String(data: data, encoding: String.Encoding.ascii)!
            let scanner = Scanner(string: line)

            if (!scanner.scanString("CHUNKSIZE", into: nil)) {
                assert(false, "Didn't get CHUNKSIZE")
            }

            var scannedChunkSize: Int32 = 0
            if !scanner.scanInt32(&scannedChunkSize) {
                assert(false, "Didn't get int value for chunksize")
            }

            assert(scannedChunkSize > 0, "Invalid chunksize")

            chunksize = UInt(scannedChunkSize)

            readLineWithTag(.rxChunksizeAccept)
        } else if tag == .rxChunksizeAccept {
            // <- ACCEPT ...

            if state == .downlinkPretestStarted {
                pretestChunksCount = 1
                writeLine("GETCHUNKS 1", withTag: .txGetChunks)
            } else if state == .uplinkPretestStarted {
                pretestChunksCount = 1
                writeLine("PUTNORESULT", withTag: .txPutNoResult)
            } else {
                assert(false, "Invalid state")
            }
        } else if tag == .txGetChunks {
            // -> GETCHUNKS X

            if pretestChunksCount == 1 {
                pretestStartNanos = RMBTCurrentNanos()
            }

            pretestLengthReceived = 0

            socket.readData(withTimeout: RMBT_TEST_SOCKET_TIMEOUT_S, tag: RMBTTestTag.rxPretestPart.rawValue)
        } else if tag == .rxPretestPart {
            pretestLengthReceived += UInt64(data.count)

            if pretestLengthReceived >= UInt64(pretestChunksCount * chunksize) {
                assert(pretestLengthReceived == UInt64(pretestChunksCount * chunksize), "Received more than expected")

                writeLine("OK", withTag: .txChunkOK)
            } else {
                // Read more
                socket.readData(withTimeout: RMBT_TEST_SOCKET_TIMEOUT_S, tag: RMBTTestTag.rxPretestPart.rawValue)
            }
        } else if tag == .txChunkOK {
            // -> OK
            readLineWithTag(.rxStatistic)
        } else if tag == .rxStatistic {
            // <- STATISTIC
            readLineWithTag(.rxStatisticAccept)
        } else if tag == .rxStatisticAccept {
            // <- ACCEPT ...

            // Did we run out of time?
            if RMBTCurrentNanos() - pretestStartNanos >= UInt64(params.pretestDuration * Double(NSEC_PER_SEC)) {
                state = .downlinkPretestFinished
                self.downlinkPretestCompleteHandler(UInt64(pretestChunksCount), RMBTCurrentNanos() - pretestStartNanos)
                delegate?.testWorker?(self, didFinishDownlinkPretestWithChunkCount: pretestChunksCount, withTime: RMBTCurrentNanos() - pretestStartNanos)
            } else {
                // ..no, get more chunks
                pretestChunksCount *= 2

                // -> GETCHUNKS *2
                writeLine("GETCHUNKS \(pretestChunksCount)", withTag: .txGetChunks)
            }
        }

        // Latency test
        else if tag == .txPing {
            // -> PING
            pingSeq += 1

            Log.logger.debug("Ping packet sent (delta = \(RMBTCurrentNanos() - self.pingStartNanos))")

            readLineWithTag(.rxPong)
        } else if tag == .rxPong {
            pingPongNanos = RMBTCurrentNanos()
            // <- PONG
            writeLine("OK", withTag: .txPongOK)
        } else if tag == .txPongOK {
            // -> OK
            readLineWithTag(.rxPongStatistic)
        } else if tag == .rxPongStatistic {
            // <- TIME
            var ns: Int64 = -1

            let line = String(data: data, encoding: String.Encoding.ascii)!
            let scanner = Scanner(string: line)

            if (!scanner.scanString("TIME", into: nil)) {
                assert(false, "Didn't get TIME statistic -> \(line)")
            }

            if !scanner.scanInt64(&ns) {
                assert(false, "Didn't get long value for latency")
            }

            assert(ns > 0, "Invalid latency time")

            delegate?.testWorker?(self, didMeasureLatencyWithServerNanos: UInt64(ns), clientNanos: pingPongNanos - pingStartNanos)
            
            var percent: Float = 0
            if params.numPings > 0 {
                percent = Float(pingSeq) / Float(params.numPings)
            }
            
            self.latencyProgressHandler(percent, UInt64(ns), pingPongNanos - pingStartNanos)
            
            readLineWithTag(.rxPongAccept)
        } else if tag == .rxPongAccept {
            // <- ACCEPT
            assert(pingSeq <= UInt(params.numPings), "Invalid ping count") // TODO

            if pingSeq == UInt(params.numPings) { // TODO
                state = .latencyTestFinished
                self.latencyCompleteHandler()
                delegate?.testWorkerDidFinishLatencyTest?(self)
            } else {
                // Send PING again
                delegate?.testWorker(self, startPing: Int(pingSeq), totalPings: params.numPings)
                writeLine("PING", withTag: .txPing)
                pingStartNanos = RMBTCurrentNanos()
            }
        }

        // Downlink test
        else if tag == .txGetTime {
            // -> GETTIME (duration)
            testDownloadedData = Data() //NSMutableData(capacity: Int(chunksize))!

            socket.readData(withTimeout: RMBT_TEST_SOCKET_TIMEOUT_S, tag: RMBTTestTag.rxDownlinkPart.rawValue)

            // We want to align starting times of all threads, so allow delegate to supply us a start timestamp
            // (usually from the first thread that reached this point)
            testStartNanos = delegate?.testWorker(self, didStartDownlinkTestAtNanos: RMBTCurrentNanos()) ?? UInt64(0.0)
        } else if tag == .rxDownlinkPart {
            let elapsedNanos = RMBTCurrentNanos() - testStartNanos
            let finished = (elapsedNanos >= UInt64(params.duration * Double(NSEC_PER_SEC)))

            if chunkData == nil {
                // We still need to fill up one chunk for transmission in upload test
                testDownloadedData.append(data)
                if testDownloadedData.count >= Int(chunksize) {
                    chunkData = testDownloadedData.subdata(in: 0..<Int(chunksize)) //NSData(data: testDownloadedData.subdata(in: NSRange(location: 0, length: Int(chunksize)))) as Data as Data
                }
            } // else discard the received data

            delegate?.testWorker(self, didDownloadLength: UInt64(data.count), atNanos: elapsedNanos)

            if finished {
                socket.disconnect()
            } else {
                // Request more
                socket.readData(withTimeout: RMBT_TEST_SOCKET_TIMEOUT_S, tag: RMBTTestTag.rxDownlinkPart.rawValue)
            }
        }

        // We always abruptly disconnect after test duration has passed, so following is not really used
        //    } else if (tag == RMBTTestTagTxGetTimeOK) {
        //        // -> OK
        //        [self readLineWithTag:RMBTTestTagRxGetTimeStatistic];
        //    } else if (tag == RMBTTestTagRxGetTimeStatistic) {
        //        // <- TIME ...
        //        [self readLineWithTag:RMBTTestTagRxGetTimeAccept];
        //    } else if (tag == RMBTTestTagRxGetTimeAccept) {
        //        // -> QUIT
        //        [self writeLine:@"QUIT" withTag:RMBTTestTagTxQuit];
        //        [_socket disconnectAfterWriting];
        //    }

        // Uplink pretest
        else if tag == .txPutNoResult {
            readLineWithTag(.rxPutNoResultOK)
        } else if tag == .rxPutNoResultOK {
            if pretestChunksCount == 1 {
                pretestStartNanos = RMBTCurrentNanos()
            }
            pretestChunksSent = 0

            updateLastChunkFlagToValue(pretestChunksCount == 1)

            writeData(chunkData as Data, withTag: .txPutNoResultChunk)
        } else if tag == .txPutNoResultChunk {
            pretestChunksSent += 1

            assert(pretestChunksSent <= pretestChunksCount)

            if pretestChunksSent == pretestChunksCount {
                readLineWithTag(.rxPutNoResultStatistic)
            } else {
                updateLastChunkFlagToValue(pretestChunksSent == (pretestChunksCount - 1))
                writeData(chunkData as Data, withTag: .txPutNoResultChunk)
            }
        } else if tag == .rxPutNoResultStatistic {
            readLineWithTag(.rxPutNoResultAccept)
        } else if tag == .rxPutNoResultAccept {
            if RMBTCurrentNanos() - pretestStartNanos >= UInt64(params.pretestDuration * Double(NSEC_PER_SEC)) {
                state = .uplinkPretestFinished
                delegate?.testWorker(self, didFinishUplinkPretestWithChunkCount: pretestChunksCount)
            } else {
                pretestChunksCount *= 2
                writeLine("PUTNORESULT", withTag: .txPutNoResult)
            }
        }

        // Uplink test
        else if tag == .txPut {
            // -> PUT
            readLineWithTag(.rxPutOK)
        } else if tag == .rxPutOK {
            testUploadLastUploadLength = 0
            testUploadLastChunkSent = false
            testStartNanos = RMBTCurrentNanos()
            testUploadOffsetNanos = delegate?.testWorker(self, didStartUplinkTestAtNanos: testStartNanos) ?? UInt64(0.0)

            var enoughInterval = (params.duration - RMBT_TEST_UPLOAD_MAX_DISCARD_S)
            if enoughInterval < 0 {
                enoughInterval = 0
            }

            testUploadEnoughServerNanos = UInt64(enoughInterval * Double(NSEC_PER_SEC))
            testUploadEnoughClientNanos = testStartNanos + UInt64((params.duration + RMBT_TEST_UPLOAD_MIN_WAIT_S) * Double(NSEC_PER_SEC))

            updateLastChunkFlagToValue(false)
            writeData(chunkData as Data, withTag: .txPutChunk)
            readLineWithTag(.rxPutStatistic)
        } else if tag == .txPutChunk {
            if testUploadLastChunkSent {
                // This was the last chunk
            } else {
                let nanos = RMBTCurrentNanos() + testUploadOffsetNanos

                if nanos - testStartNanos >= UInt64(params.duration * Double(NSEC_PER_SEC)) {
                    Log.logger.debug("Sending last chunk in thread \(self.index)")

                    testUploadLastChunkSent = true
                    testUploadMaxWaitReachedClientNanos = RMBTCurrentNanos() + UInt64(RMBT_TEST_UPLOAD_MAX_WAIT_S) * NSEC_PER_SEC

                    // We're done, send last chunk
                    updateLastChunkFlagToValue(true)
                }

                writeData(chunkData as Data, withTag: .txPutChunk)
            }
        } else if tag == .rxPutStatistic {
            // <- TIME

            let line = String(data: data, encoding: String.Encoding.ascii)! // !

            if line.hasPrefix("TIME") {
                var ns: Int64 = -1
                var bytes: Int64 = -1

                let scanner = Scanner(string: line)

                // redundant, remove?
                if (!scanner.scanString("TIME", into: nil)) {
                    assert(false, "Didn't scan TIME")
                }

                if !scanner.scanInt64(&ns) {
                    assert(false, "Didn't get long value for TIME")
                }

                assert(ns > 0, "Invalid time")

                if scanner.scanString("BYTES", into: nil) {
                    if !scanner.scanInt64(&bytes) {
                        assert(false, "Didn't get long value for BYTES")
                    }

                    assert(bytes > 0, "Invalid bytes")
                }

                ns += Int64(testUploadOffsetNanos)

                // Did upload
                if bytes > 0 {
                    delegate?.testWorker(self, didUploadLength: UInt64(bytes) - testUploadLastUploadLength, atNanos: UInt64(ns))
                    testUploadLastUploadLength = UInt64(bytes)
                }

                let now = RMBTCurrentNanos()

                if testUploadLastChunkSent && now >= testUploadMaxWaitReachedClientNanos {
                    Log.logger.debug("Max wait reached in thread \(self.index). Finalizing.")
                    finalize()
                    return
                }

                if testUploadLastChunkSent && now >= testUploadEnoughClientNanos && UInt64(ns) >= testUploadEnoughServerNanos {
                    // We can finalize
                    Log.logger.debug("Thread \(self.index) has read enough upload reports at local=\(now - self.testStartNanos) server=\(ns). Finalizing...")
                    finalize()
                    return
                }

                readLineWithTag(.rxPutStatistic)
            } else if line.hasPrefix("ACCEPT") {
                Log.logger.debug("Thread \(self.index) has read ALL upload reports. Finalizing...")
                finalize()
            } else {
                // INVALID LINE
                assert(false, "Invalid response received")
                Log.logger.debug("Protocol error")
                fail()
            }
        } else {
            assert(false, "RX/TX with unknown tag \(tag)")
            Log.logger.debug("Protocol error")
            fail()
        }
    }

    /// Finishes the uplink test and closes the connection
    override open func finalize() {
        state = .uplinkTestFinished

        socket.disconnect()
        delegate?.testWorkerDidFinishUplinkTest(self)
    }

// MARK: Socket helpers

    ///
    private func readLineWithTag(_ tag: RMBTTestTag) {
        if let data = "\n".data(using: String.Encoding.ascii) {
            socket.readData(to: data, withTimeout: RMBT_TEST_SOCKET_TIMEOUT_S, tag: tag.rawValue)
        }
    }

    ///
    private func writeLine(_ line: String, withTag tag: RMBTTestTag) {
        writeData((line + "\n").data(using: String.Encoding.ascii)!, withTag: tag) // !
    }

    ///
    private func writeData(_ data: Data, withTag tag: RMBTTestTag) {
        totalBytesUploaded += UInt64(data.count)
        socket.write(data, withTimeout: RMBT_TEST_SOCKET_TIMEOUT_S, tag: tag.rawValue)
    }

    ///
    private func logData(_ data: Data) {
        Log.logger.debug("RX: \(String(describing: String(data: data, encoding: String.Encoding.ascii)))")
    }

    ///
    private func isLastChunk(_ data: Data) -> Bool {
        var bytes = [UInt8](repeating: 0, count: (data.count / MemoryLayout<UInt8>.size)) // TODO: better way?
        (data as NSData).getBytes(&bytes, length: bytes.count) // TODO: better way?
        //data.getBytes(&bytes,) // TODO: better way?

        let lastByte: UInt8 = bytes[data.count - 1]

        return lastByte == 0xff
    }

    ///
    private func updateLastChunkFlagToValue(_ lastChunk: Bool) {
        var lastByte: UInt8 = lastChunk ? 0xff : 0x00
        
        let lastByteData = Data(buffer: UnsafeBufferPointer(start: &lastByte, count: 1)) //Data(bytes: &lastByte, count: 1)

        // old
        // chunkData.replaceBytesInRange(NSRange(location: chunkData.length - 1, length: 1), withBytes: &lastByte)
        // ??????
        chunkData.replaceSubrange(chunkData.count-1..<chunkData.count, with: lastByteData)
    }
}
