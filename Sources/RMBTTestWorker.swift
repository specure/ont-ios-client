//
//  RMBTTestWorker.swift
//  RMBT
//
//  Created by Benjamin Pucher on 15.09.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

///
public enum RMBTTestWorkerState: Int {
    case Initialized

    case DownlinkPretestStarted
    case DownlinkPretestFinished

    case LatencyTestStarted
    case LatencyTestFinished

    case DownlinkTestStarted
    case DownlinkTestFinished

    case UplinkPretestStarted
    case UplinkPretestFinished

    case UplinkTestStarted
    case UplinkTestFinished

    case Stopping
    case Stopped

    case Aborted
    case Failed
}

/// We use long to be compatible with GCDAsyncSocket tag datatype
public enum RMBTTestTag: Int {
    case RxPretestPart = -2
    case RxDownlinkPart = -1

    case RxBanner = 1
    case RxBannerAccept
    case TxToken
    case RxTokenOK
    case RxChunksize
    case RxChunksizeAccept
    case TxGetChunks
    case RxChunk
    case TxChunkOK
    case RxStatistic
    case RxStatisticAccept
    case TxPing
    case RxPong
    case TxPongOK
    case RxPongStatistic
    case RxPongAccept
    case TxGetTime
    case RxGetTime
    case RxGetTimeLeftoverChunk
    case TxGetTimeOK
    case RxGetTimeStatistic
    case RxGetTimeAccept
    case TxQuit
    case TxPutNoResult
    case RxPutNoResultOK
    case TxPutNoResultChunk
    case RxPutNoResultStatistic
    case RxPutNoResultAccept
    case TxPut
    case RxPutOK
    case TxPutChunk
    case RxPutStatistic
    case RxPutStatisticLast
}

/// All delegate methods are dispatched on the supplied delegate queue
public protocol RMBTTestWorkerDelegate {

    ///
    func testWorker(worker: RMBTTestWorker, didFinishDownlinkPretestWithChunkCount chunks: UInt, withTime duration: UInt64)

    ///
    func testWorker(worker: RMBTTestWorker, didMeasureLatencyWithServerNanos serverNanos: UInt64, clientNanos: UInt64)

    ///
    func testWorkerDidFinishLatencyTest(worker: RMBTTestWorker)

    ///
    func testWorker(worker: RMBTTestWorker, didStartDownlinkTestAtNanos nanos: UInt64) -> UInt64

    ///
    func testWorker(worker: RMBTTestWorker, didDownloadLength length: UInt64, atNanos nanos: UInt64)

    ///
    func testWorkerDidFinishDownlinkTest(worker: RMBTTestWorker)

    ///
    func testWorker(worker: RMBTTestWorker, didFinishUplinkPretestWithChunkCount chunks: UInt)

    ///
    func testWorker(worker: RMBTTestWorker, didStartUplinkTestAtNanos nanos: UInt64) -> UInt64

    ///
    func testWorker(worker: RMBTTestWorker, didUploadLength length: UInt64, atNanos nanos: UInt64)

    ///
    func testWorkerDidFinishUplinkTest(worker: RMBTTestWorker)

    ///
    func testWorkerDidStop(worker: RMBTTestWorker)

    ///
    func testWorkerDidFail(worker: RMBTTestWorker)
}

///
public class RMBTTestWorker: NSObject, GCDAsyncSocketDelegate {

    // Test parameters
    private var params: SpeedMeasurmentResponse//RMBTTestParams

    /// Weak reference to the delegate
    private let delegate: RMBTTestWorkerDelegate

    /// Current state of the worker
    private var state: RMBTTestWorkerState = .Initialized

    ///
    private var socket: GCDAsyncSocket!

    /// CHUNKSIZE received from server
    private var chunksize: UInt = 0

    /// One chunk of data cached from the downlink phase, to be used as upload data
    private var chunkData: NSMutableData!

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
    private var testDownloadedData: NSMutableData!

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
    public var index: UInt

    ///
    public var totalBytesUploaded: UInt64 = 0

    ///
    public var totalBytesDownloaded: UInt64 = 0

    ///
    public var negotiatedEncryptionString: String!

    ///
    public var localIp: String!

    ///
    public var serverIp: String!

    ///
    public init(delegate: RMBTTestWorkerDelegate, delegateQueue: dispatch_queue_t, index: UInt, testParams: SpeedMeasurmentResponse) {
        self.delegate = delegate
        self.index = index
        self.params = testParams
        //self.state = .Initialized

        super.init()

        socket = GCDAsyncSocket(delegate: self, delegateQueue: delegateQueue)
    }

// MARK: State handling

    ///
    public func startDownlinkPretest() {
        assert(state == .Initialized, "Invalid state")

        state = .DownlinkPretestStarted

        connect()
    }

    ///
    public func stop() {
        assert(state == .DownlinkPretestFinished, "Invalid state")

        state = .Stopping

        socket.disconnect()
    }

    ///
    public func startLatencyTest() {
        assert(state == .DownlinkPretestFinished, "Invalid state")

        state = .LatencyTestStarted

        pingSeq = 0
        writeLine("PING", withTag: .TxPing)

        pingStartNanos = RMBTCurrentNanos()
    }

    ///
    public func startDownlinkTest() {
        assert(state == .LatencyTestFinished || state == .DownlinkPretestFinished, "Invalid state")

        state = .DownlinkTestStarted

        writeLine("GETTIME \(Int(params.duration))", withTag: .TxGetTime)
    }

    ///
    public func startUplinkPretest() {
        assert(state == .DownlinkTestFinished, "Invalid state")

        state = .UplinkPretestStarted

        connect()
    }

    ///
    public func startUplinkTest() {
        assert(state == .UplinkPretestFinished, "Invalid state")

        state = .UplinkTestStarted

        writeLine("PUT", withTag: .TxPut)
    }

// MARK: ...

    private func tryDNSLookup(serverName: String) -> String? {
        let host = CFHostCreateWithName(nil, serverName).takeRetainedValue()
        CFHostStartInfoResolution(host, .Addresses, nil)
        var success: DarwinBoolean = false
        if let addresses = CFHostGetAddressing(host, &success)?.takeUnretainedValue() as NSArray?,
            let theAddress = addresses.firstObject as? NSData {
                var hostname = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
                if getnameinfo(UnsafePointer(theAddress.bytes), socklen_t(theAddress.length),
                    &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                        if let numAddress = String.fromCString(hostname) {
                            return numAddress
                        }
                }
        }

        return nil
    }

    ///
    public func connect() {
        do {
            // iOS 9: fails with socketDidDisconnect(_:withError:) > Socket disconnected with error Error Domain=kCFStreamErrorDomainNetDB Code=8
            // "nodename nor servname provided, or not known" UserInfo={NSLocalizedDescription=nodename nor servname provided, or not known}

            // try dns lookup first as a workaround for the ios 9 bug
            var sAddr = params.measurementServer?.address ?? "" // TODO
            if let ip = tryDNSLookup(sAddr) {
                sAddr = ip
            }
            
            logger.debug("Connecting to host \(sAddr):\(params.measurementServer!.port!)")

            try socket.connectToHost(sAddr, onPort: UInt16(params.measurementServer!.port!) /*TODO*/, withTimeout: RMBT_TEST_SOCKET_TIMEOUT_S)

        } catch {
            //fail() // at this point, no error is checked, see https://github.com/appscape/open-rmbt-ios/blob/master/Sources/RMBTTestWorker.m
        }
    }

    ///
    public func abort() {
        if state == .Aborted {
            return
        }

        state = .Aborted

        if socket.isConnected {
            socket.disconnect()
        }
    }

    ///
    public func fail() {
        if state == .Failed {
            return
        }

        state = .Failed

        delegate.testWorkerDidFail(self)

        if socket.isConnected {
            socket.disconnect()
        }
    }

// MARK: Socket delegate methods

    ///
    public func socket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        if state == .Aborted {
            sock.disconnect()
            return
        }

        assert(state == .DownlinkPretestStarted || state == .UplinkPretestStarted, "Invalid state")

        localIp = sock.localHost
        serverIp = sock.connectedHost

        if let ms = params.measurementServer where ms.encrypted { // TODO
            sock.startTLS([
                GCDAsyncSocketManuallyEvaluateTrust: true
            ])
        } else {
            readLineWithTag(.RxBanner)
        }
    }

    ///
    public func socket(sock: GCDAsyncSocket!, didReceiveTrust trust: SecTrust!, completionHandler: ((Bool) -> Void)!) {
        completionHandler(true)
    }

    ///
    public func socketDidSecure(sock: GCDAsyncSocket!) {
        assert(state == .DownlinkPretestStarted || state == .UplinkPretestStarted, "Invalid state")

        socket.performBlock {
            self.negotiatedEncryptionString = RMBTSSLHelper.encryptionStringForSSLContext(sock.sslContext().takeUnretainedValue()) // TODO: or use takeRetainedValue()?
        }

        readLineWithTag(.RxBanner)
    }

    ///
    public func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        if err != nil {
            logger.debug("Socket disconnected with error \(err)")
            fail()
        } else {
            if state == .DownlinkTestStarted {
                state = .DownlinkTestFinished
                delegate.testWorkerDidFinishDownlinkTest(self)
            } else if state == .Stopping {
                state = .Stopped
                delegate.testWorkerDidStop(self)
            } else if state == .Failed || state == .Aborted || state == .UplinkTestFinished {
                // We've finished/aborted/failed and socket has disconnected. Nothing to do!
            } else {
                assert(false, "Disconnection in an unexpected state")
            }
        }
    }

    ///
    public func socket(sock: GCDAsyncSocket!, didWriteDataWithTag tag: Int) {
        if state == .Aborted {
            return
        }

        socketDidReadOrWriteData(nil, withTag: tag, read: false)
    }

    ///
    public func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        if state == .Aborted {
            return
        }

        totalBytesDownloaded += UInt64(data.length)

        socketDidReadOrWriteData(data, withTag: tag, read: true)
    }

    /// We unify read and write callbacks for better state documentation
    public func socketDidReadOrWriteData(data: NSData!, withTag tagRaw: Int, read: Bool) {
        let tag = RMBTTestTag(rawValue: tagRaw)!

        // Pretest
        if tag == .RxBanner {
            // <- RMBTv0.3
            readLineWithTag(.RxBannerAccept)
        } else if tag == .RxBannerAccept {
            // <- ACCEPT
            writeLine("TOKEN \(params.testToken!)", withTag: .TxToken) // TODO: optionals!!!
        } else if tag == .TxToken {
            // -> TOKEN ...
            readLineWithTag(.RxTokenOK)
        } else if tag == .RxTokenOK {
            // <- OK
            readLineWithTag(.RxChunksize)
        } else if tag == .RxChunksize {
            // <- CHUNKSIZE

            let line = String(data: data, encoding: NSASCIIStringEncoding)!
            let scanner = NSScanner(string: line)

            if (!scanner.scanString("CHUNKSIZE", intoString: nil)) {
                assert(false, "Didn't get CHUNKSIZE")
            }

            var scannedChunkSize: Int32 = 0
            if !scanner.scanInt(&scannedChunkSize) {
                assert(false, "Didn't get int value for chunksize")
            }

            assert(scannedChunkSize > 0, "Invalid chunksize")

            chunksize = UInt(scannedChunkSize)

            readLineWithTag(.RxChunksizeAccept)
        } else if tag == .RxChunksizeAccept {
            // <- ACCEPT ...

            if state == .DownlinkPretestStarted {
                pretestChunksCount = 1
                writeLine("GETCHUNKS 1", withTag: .TxGetChunks)
            } else if state == .UplinkPretestStarted {
                pretestChunksCount = 1
                writeLine("PUTNORESULT", withTag: .TxPutNoResult)
            } else {
                assert(false, "Invalid state")
            }
        } else if tag == .TxGetChunks {
            // -> GETCHUNKS X

            if pretestChunksCount == 1 {
                pretestStartNanos = RMBTCurrentNanos()
            }

            pretestLengthReceived = 0

            socket.readDataWithTimeout(RMBT_TEST_SOCKET_TIMEOUT_S, tag: RMBTTestTag.RxPretestPart.rawValue)
        } else if tag == .RxPretestPart {
            pretestLengthReceived += UInt64(data.length)

            if pretestLengthReceived >= UInt64(pretestChunksCount * chunksize) {
                assert(pretestLengthReceived == UInt64(pretestChunksCount * chunksize), "Received more than expected")

                writeLine("OK", withTag: .TxChunkOK)
            } else {
                // Read more
                socket.readDataWithTimeout(RMBT_TEST_SOCKET_TIMEOUT_S, tag: RMBTTestTag.RxPretestPart.rawValue)
            }
        } else if tag == .TxChunkOK {
            // -> OK
            readLineWithTag(.RxStatistic)
        } else if tag == .RxStatistic {
            // <- STATISTIC
            readLineWithTag(.RxStatisticAccept)
        } else if tag == .RxStatisticAccept {
            // <- ACCEPT ...

            // Did we run out of time?
            if RMBTCurrentNanos() - pretestStartNanos >= UInt64(params.pretestDuration * Double(NSEC_PER_SEC)) {
                state = .DownlinkPretestFinished
                delegate.testWorker(self, didFinishDownlinkPretestWithChunkCount: pretestChunksCount, withTime: RMBTCurrentNanos() - pretestStartNanos)
            } else {
                // ..no, get more chunks
                pretestChunksCount *= 2

                // -> GETCHUNKS *2
                writeLine("GETCHUNKS \(pretestChunksCount)", withTag: .TxGetChunks)
            }
        }

        // Latency test
        else if tag == .TxPing {
            // -> PING
            pingSeq += 1

            logger.debug("Ping packet sent (delta = \(RMBTCurrentNanos() - pingStartNanos))")

            readLineWithTag(.RxPong)
        } else if tag == .RxPong {
            pingPongNanos = RMBTCurrentNanos()
            // <- PONG
            writeLine("OK", withTag: .TxPongOK)
        } else if tag == .TxPongOK {
            // -> OK
            readLineWithTag(.RxPongStatistic)
        } else if tag == .RxPongStatistic {
            // <- TIME
            var ns: Int64 = -1

            let line = String(data: data, encoding: NSASCIIStringEncoding)!
            let scanner = NSScanner(string: line)

            if (!scanner.scanString("TIME", intoString: nil)) {
                assert(false, "Didn't get TIME statistic -> \(line)")
            }

            if !scanner.scanLongLong(&ns) {
                assert(false, "Didn't get long value for latency")
            }

            assert(ns > 0, "Invalid latency time")

            delegate.testWorker(self, didMeasureLatencyWithServerNanos: UInt64(ns), clientNanos: pingPongNanos - pingStartNanos)

            readLineWithTag(.RxPongAccept)
        } else if tag == .RxPongAccept {
            // <- ACCEPT
            assert(pingSeq <= UInt(params.numPings), "Invalid ping count") // TODO

            if pingSeq == UInt(params.numPings) { // TODO
                state = .LatencyTestFinished
                delegate.testWorkerDidFinishLatencyTest(self)
            } else {
                // Send PING again
                writeLine("PING", withTag: .TxPing)
                pingStartNanos = RMBTCurrentNanos()
            }
        }

        // Downlink test
        else if tag == .TxGetTime {
            // -> GETTIME (duration)
            testDownloadedData = NSMutableData(capacity: Int(chunksize))!

            socket.readDataWithTimeout(RMBT_TEST_SOCKET_TIMEOUT_S, tag: RMBTTestTag.RxDownlinkPart.rawValue)

            // We want to align starting times of all threads, so allow delegate to supply us a start timestamp
            // (usually from the first thread that reached this point)
            testStartNanos = delegate.testWorker(self, didStartDownlinkTestAtNanos: RMBTCurrentNanos())
        } else if tag == .RxDownlinkPart {
            let elapsedNanos = RMBTCurrentNanos() - testStartNanos
            let finished = (elapsedNanos >= UInt64(params.duration * Double(NSEC_PER_SEC)))

            if chunkData == nil {
                // We still need to fill up one chunk for transmission in upload test
                testDownloadedData.appendData(data)
                if testDownloadedData.length >= Int(chunksize) {
                    chunkData = NSMutableData(data: testDownloadedData.subdataWithRange(NSRange(location: 0, length: Int(chunksize))))
                }
            } // else discard the received data

            delegate.testWorker(self, didDownloadLength: UInt64(data.length), atNanos: elapsedNanos)

            if finished {
                socket.disconnect()
            } else {
                // Request more
                socket.readDataWithTimeout(RMBT_TEST_SOCKET_TIMEOUT_S, tag: RMBTTestTag.RxDownlinkPart.rawValue)
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
        else if tag == .TxPutNoResult {
            readLineWithTag(.RxPutNoResultOK)
        } else if tag == .RxPutNoResultOK {
            if pretestChunksCount == 1 {
                pretestStartNanos = RMBTCurrentNanos()
            }
            pretestChunksSent = 0

            updateLastChunkFlagToValue(pretestChunksCount == 1)

            writeData(chunkData, withTag: .TxPutNoResultChunk)
        } else if tag == .TxPutNoResultChunk {
            pretestChunksSent += 1

            assert(pretestChunksSent <= pretestChunksCount)

            if pretestChunksSent == pretestChunksCount {
                readLineWithTag(.RxPutNoResultStatistic)
            } else {
                updateLastChunkFlagToValue(pretestChunksSent == (pretestChunksCount - 1))
                writeData(chunkData, withTag: .TxPutNoResultChunk)
            }
        } else if tag == .RxPutNoResultStatistic {
            readLineWithTag(.RxPutNoResultAccept)
        } else if tag == .RxPutNoResultAccept {
            if RMBTCurrentNanos() - pretestStartNanos >= UInt64(params.pretestDuration * Double(NSEC_PER_SEC)) {
                state = .UplinkPretestFinished
                delegate.testWorker(self, didFinishUplinkPretestWithChunkCount: pretestChunksCount)
            } else {
                pretestChunksCount *= 2
                writeLine("PUTNORESULT", withTag: .TxPutNoResult)
            }
        }

        // Uplink test
        else if tag == .TxPut {
            // -> PUT
            readLineWithTag(.RxPutOK)
        } else if tag == .RxPutOK {
            testUploadLastUploadLength = 0
            testUploadLastChunkSent = false
            testStartNanos = RMBTCurrentNanos()
            testUploadOffsetNanos = delegate.testWorker(self, didStartUplinkTestAtNanos: testStartNanos)

            var enoughInterval = (params.duration - RMBT_TEST_UPLOAD_MAX_DISCARD_S)
            if enoughInterval < 0 {
                enoughInterval = 0
            }

            testUploadEnoughServerNanos = UInt64(enoughInterval * Double(NSEC_PER_SEC))
            testUploadEnoughClientNanos = testStartNanos + UInt64((params.duration + RMBT_TEST_UPLOAD_MIN_WAIT_S) * Double(NSEC_PER_SEC))

            updateLastChunkFlagToValue(false)
            writeData(chunkData, withTag: .TxPutChunk)
            readLineWithTag(.RxPutStatistic)
        } else if tag == .TxPutChunk {
            if testUploadLastChunkSent {
                // This was the last chunk
            } else {
                let nanos = RMBTCurrentNanos() + testUploadOffsetNanos

                if nanos - testStartNanos >= UInt64(params.duration * Double(NSEC_PER_SEC)) {
                    logger.debug("Sending last chunk in thread \(index)")

                    testUploadLastChunkSent = true
                    testUploadMaxWaitReachedClientNanos = RMBTCurrentNanos() + UInt64(RMBT_TEST_UPLOAD_MAX_WAIT_S) * NSEC_PER_SEC

                    // We're done, send last chunk
                    updateLastChunkFlagToValue(true)
                }

                writeData(chunkData, withTag: .TxPutChunk)
            }
        } else if tag == .RxPutStatistic {
            // <- TIME

            let line = String(data: data, encoding: NSASCIIStringEncoding)! // !

            if line.hasPrefix("TIME") {
                var ns: Int64 = -1
                var bytes: Int64 = -1

                let scanner = NSScanner(string: line)

                // redundant, remove?
                if (!scanner.scanString("TIME", intoString: nil)) {
                    assert(false, "Didn't scan TIME")
                }

                if !scanner.scanLongLong(&ns) {
                    assert(false, "Didn't get long value for TIME")
                }

                assert(ns > 0, "Invalid time")

                if scanner.scanString("BYTES", intoString: nil) {
                    if !scanner.scanLongLong(&bytes) {
                        assert(false, "Didn't get long value for BYTES")
                    }

                    assert(bytes > 0, "Invalid bytes")
                }

                ns += Int64(testUploadOffsetNanos)

                // Did upload
                if bytes > 0 {
                    delegate.testWorker(self, didUploadLength: UInt64(bytes) - testUploadLastUploadLength, atNanos: UInt64(ns))
                    testUploadLastUploadLength = UInt64(bytes)
                }

                let now = RMBTCurrentNanos()

                if testUploadLastChunkSent && now >= testUploadMaxWaitReachedClientNanos {
                    logger.debug("Max wait reached in thread \(index). Finalizing.")
                    finalize()
                    return
                }

                if testUploadLastChunkSent && now >= testUploadEnoughClientNanos && UInt64(ns) >= testUploadEnoughServerNanos {
                    // We can finalize
                    logger.debug("Thread \(index) has read enough upload reports at local=\(now - testStartNanos) server=\(ns). Finalizing...")
                    finalize()
                    return
                }

                readLineWithTag(.RxPutStatistic)
            } else if line.hasPrefix("ACCEPT") {
                logger.debug("Thread \(index) has read ALL upload reports. Finalizing...")
                finalize()
            } else {
                // INVALID LINE
                assert(false, "Invalid response received")
                logger.debug("Protocol error")
                fail()
            }
        } else {
            assert(false, "RX/TX with unknown tag \(tag)")
            logger.debug("Protocol error")
            fail()
        }
    }

    /// Finishes the uplink test and closes the connection
    override public func finalize() {
        state = .UplinkTestFinished

        socket.disconnect()
        delegate.testWorkerDidFinishUplinkTest(self)
    }

// MARK: Socket helpers

    ///
    private func readLineWithTag(tag: RMBTTestTag) {
        socket.readDataToData("\n".dataUsingEncoding(NSASCIIStringEncoding), withTimeout: RMBT_TEST_SOCKET_TIMEOUT_S, tag: tag.rawValue)
    }

    ///
    private func writeLine(line: String, withTag tag: RMBTTestTag) {
        writeData(line.stringByAppendingString("\n").dataUsingEncoding(NSASCIIStringEncoding)!, withTag: tag) // !
    }

    ///
    private func writeData(data: NSData, withTag tag: RMBTTestTag) {
        totalBytesUploaded += UInt64(data.length)
        socket.writeData(data, withTimeout: RMBT_TEST_SOCKET_TIMEOUT_S, tag: tag.rawValue)
    }

    ///
    private func logData(data: NSData) {
        logger.debug("RX: \(String(data: data, encoding: NSASCIIStringEncoding))")
    }

    ///
    private func isLastChunk(data: NSData) -> Bool {
        var bytes = [UInt8](count: (data.length / sizeof(UInt8)), repeatedValue: 0) // TODO: better way?
        data.getBytes(&bytes, length: bytes.count) // TODO: better way?
        //data.getBytes(&bytes,) // TODO: better way?

        let lastByte: UInt8 = bytes[data.length - 1]

        return lastByte == 0xff
    }

    ///
    private func updateLastChunkFlagToValue(lastChunk: Bool) {
        var lastByte: UInt8 = lastChunk ? 0xff : 0x00

        chunkData.replaceBytesInRange(NSRange(location: chunkData.length - 1, length: 1), withBytes: &lastByte)
    }
}
