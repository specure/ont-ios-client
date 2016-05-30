//
//  QOSControlConnection.swift
//  RMBT
//
//  Created by Benjamin Pucher on 09.12.14.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

class QOSControlConnection {

    private let TAG_GREETING = -1
    private let TAG_FIRST_ACCEPT = -2
    private let TAG_TOKEN = -3
    //private let TAG_OK = -4
    private let TAG_SECOND_ACCEPT = -4

    private let TAG_SET_TIMEOUT = -10

    private let TAG_TASK_COMMAND = -100

    //

    ///
    var delegate: QOSControlConnectionDelegate?

    ///
    var connected = false

    ///
    private let testToken: String

    ///
    private let connectCountDownLatch = CountDownLatch()

    ///
    private let socketQueue = dispatch_queue_create("com.specure.rmbt.controlConnectionSocketQueue", DISPATCH_QUEUE_CONCURRENT)

    ///
    private var qosControlConnectionSocket: GCDAsyncSocket!

    ///
    private var taskDelegateDictionary = [UInt: QOSControlConnectionTaskDelegate]()

    ///
    private var pendingTimeout: Double = 0
    private var currentTimeout: Double = 0

    //

    ///
    init(testToken: String) {
        self.testToken = testToken

        // create socket
        qosControlConnectionSocket = GCDAsyncSocket(delegate: self, delegateQueue: socketQueue) // TODO: specify other dispath queue

        logger.verbose("control connection created")
    }

// MARK: connection handling

    ///
    func connect(host: String, onPort port: UInt16) -> Bool {
        return connect(host, onPort: port, withTimeout: QOS_CONTROL_CONNECTION_TIMEOUT_NS)
    }

    ///
    func connect(host: String, onPort port: UInt16, withTimeout timeout: UInt64) -> Bool {
        let connectTimeout = nsToSec(timeout)

        do {
            try qosControlConnectionSocket.connectToHost(host, onPort: port, withTimeout: connectTimeout)
        } catch {
            // there was an error
            logger.verbose("connection error \(error)")
        }

        connectCountDownLatch.await(timeout)

        return connected
    }

    ///
    func disconnect() {
        // send quit
        logger.debug("QUIT QUIT QUIT QUIT QUIT")

        writeLine("QUIT", withTimeout: QOS_CONTROL_CONNECTION_TIMEOUT_SEC, tag: -1) // don't bother with the tag, don't need read after this operation
        qosControlConnectionSocket.disconnectAfterWriting()
        // qosControlConnectionSocket.disconnectAfterReadingAndWriting()
    }

// MARK: commands

    ///
    func setTimeout(timeout: UInt64) {
        // logger.debug("SET TIMEOUT: \(timeout)")

        // timeout is in nanoseconds -> convert to ms
        var msTimeout = nsToMs(timeout)

        // if msTimeout is lower than 15 seconds, increase it
        if msTimeout < 15_000 {
            msTimeout = 15_000
        }

        if currentTimeout == msTimeout {
            logger.debug("skipping change of control connection timeout because old value = new value")
            return // skip if old == new timeout
        }

        pendingTimeout = msTimeout

        // logger.debug("REQUEST CONN TIMEOUT \(msTimeout)")
        writeLine("REQUEST CONN TIMEOUT \(msTimeout)", withTimeout: QOS_CONTROL_CONNECTION_TIMEOUT_SEC, tag: TAG_SET_TIMEOUT)
        readLine(TAG_SET_TIMEOUT, withTimeout: QOS_CONTROL_CONNECTION_TIMEOUT_SEC)
    }

// MARK: control connection delegate methods

    ///
    func registerTaskDelegate(delegate: QOSControlConnectionTaskDelegate, forTaskId taskId: UInt) {
        taskDelegateDictionary[taskId] = delegate
        logger.debug("registerTaskDelegate: \(taskId), delegate: \(delegate)")
    }

    ///
    func unregisterTaskDelegate(forTaskId taskId: UInt) {
        taskDelegateDictionary.removeValueForKey(taskId)
        // taskDelegateDictionary[taskId] = nil
    }

// MARK: task command methods

    // TODO: use closure instead of delegate methods
    /// command should not contain \n, will be added inside this method
    func sendTaskCommand(command: String, withTimeout timeout: NSTimeInterval, forTaskId taskId: UInt, tag: Int) {
        /* if (!qosControlConnectionSocket.isConnected) {
            logger.error("control connection is closed, sendTaskCommand won't work!")
        } */

        let _command = command + " +ID\(taskId)"

        let t = createTaskCommandTag(forTaskId: taskId, tag: tag)
        logger.verbose("SENDTASKCOMMAND: (taskId: \(taskId), tag: \(tag)) -> \(t) (\(String(t, radix: 2)))")

        // write command
        writeLine(_command, withTimeout: timeout, tag: t)

        // and then read? // TODO: or use thread with looped readLine?
        readLine(t, withTimeout: timeout)
    }

    /// command should not contain \n, will be added inside this method
    func sendTaskCommand(command: String, withTimeout timeout: NSTimeInterval, forTaskId taskId: UInt) {
        sendTaskCommand(command, withTimeout: timeout, forTaskId: taskId, tag: TAG_TASK_COMMAND)
    }

// MARK: convenience methods

    ///
    private func writeLine(line: String, withTimeout timeout: NSTimeInterval, tag: Int) {
        SocketUtils.writeLine(qosControlConnectionSocket, line: line, withTimeout: timeout, tag: tag)
    }

    ///
    private func readLine(tag: Int, withTimeout timeout: NSTimeInterval) {
        SocketUtils.readLine(qosControlConnectionSocket, tag: tag, withTimeout: timeout)
    }

// MARK: other methods

    ///
    private func createTaskCommandTag(forTaskId taskId: UInt, tag: Int) -> Int {
        // bitfield: 0111|aaaa_aaaa_aaaa|bbbb_bbbb_bbbb_bbbb

        var bitfield: UInt32 = 0x7

        bitfield = bitfield << 12

        bitfield = bitfield + (UInt32(abs(tag)) & 0x0000_0FFF)

        bitfield = bitfield << 16

        bitfield = bitfield + (UInt32(taskId) & 0x0000_FFFF)

        // logger.verbose("created BITFIELD for taskId: \(taskId), tag: \(tag) -> \(String(bitfield, radix: 2))")
        // logger.verbose("created BITFIELD for taskId: \(taskId), tag: \(tag) -> \(String(Int(bitfield), radix: 2))")

        return Int(bitfield)
    }

    ///
    private func parseTaskCommandTag(taskCommandTag commandTag: Int) -> (taskId: UInt, tag: Int)? {
        let _commandTag = UInt(commandTag)

        if !isTaskCommandTag(taskCommandTag: commandTag) {
            return nil // not a valid task command tag
        }

        let taskId: UInt = _commandTag & 0x0000_FFFF
        let tag = Int((_commandTag & 0x0FFF_0000) >> 16)

        logger.verbose("BITFIELD2: \(commandTag) -> (taskId: \(taskId), tag: \(tag))")

        return (taskId, tag)
    }

    ///
    private func isTaskCommandTag(taskCommandTag commandTag: Int) -> Bool {
        if commandTag < 0 {
            return false
        }

        return UInt(commandTag) & 0x7000_0000 == 0x7000_0000
    }

    ///
    private func matchAndGetTestIdFromResponse(response: String) -> UInt? {
        do {
            let regex = try NSRegularExpression(pattern: "\\+ID(\\d*)", options: [])

            if let match = regex.firstMatchInString(response, options: [], range: NSRange(location: 0, length: response.characters.count)) {
                // println(match)

                if match.numberOfRanges > 0 {
                    let idStr = (response as NSString).substringWithRange(match.rangeAtIndex(1))

                    // return UInt(idStr.toInt()) // does not work because of Int?
                    return UInt(idStr)
                }
            }
        } catch {
            // TODO?
        }

        return nil
    }

}

// MARK: GCDAsyncSocketDelegate methods

///
extension QOSControlConnection: GCDAsyncSocketDelegate {

    ///
    @objc func socket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        logger.verbose("connected to host \(host) on port \(port)")

        // control connection to qos server uses tls
        sock.startTLS(QOS_TLS_SETTINGS)
    }

    @objc func socket(sock: GCDAsyncSocket!, didReceiveTrust trust: SecTrust!, completionHandler: ((Bool) -> Void)!) {
        logger.verbose("DID RECEIVE TRUST")
        completionHandler(true)
    }

    ///
    @objc func socketDidSecure(sock: GCDAsyncSocket!) {
        logger.verbose("socketDidSecure")

        // tls connection has been established, start with QTP handshake
        readLine(TAG_GREETING, withTimeout: QOS_CONTROL_CONNECTION_TIMEOUT_SEC)
    }

    ///
    @objc func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        logger.verbose("didReadData \(data) with tag \(tag)")

        let str: String = SocketUtils.parseResponseToString(data)!

        logger.verbose("didReadData \(str)")

        switch tag {
        case TAG_GREETING:
            // got greeting
            logger.verbose("got greeting")

            // read accept
            readLine(TAG_FIRST_ACCEPT, withTimeout: QOS_CONTROL_CONNECTION_TIMEOUT_SEC)

        case TAG_FIRST_ACCEPT:
            // got accept
            logger.verbose("got accept")

            // send token
            let tokenCommand = "TOKEN \(testToken)\n"
            writeLine(tokenCommand, withTimeout: QOS_CONTROL_CONNECTION_TIMEOUT_SEC, tag: TAG_TOKEN)

            // read token response
            readLine(TAG_TOKEN, withTimeout: QOS_CONTROL_CONNECTION_TIMEOUT_SEC)

        case TAG_TOKEN:
            // response from token command
            logger.verbose("got ok")

            // read second accept
            readLine(TAG_SECOND_ACCEPT, withTimeout: QOS_CONTROL_CONNECTION_TIMEOUT_SEC)

        case TAG_SECOND_ACCEPT:
            // got second accept
            logger.verbose("got second accept")

            // now connection is ready
            logger.verbose("CONNECTION READY")

            connected = true // set connected to true to unlock
            connectCountDownLatch.countDown()

            // call delegate method // TODO: on which queue?
            self.delegate?.controlConnectionReadyToUse(self)

            //
        case TAG_SET_TIMEOUT:
            // return from REQUEST CONN TIMEOUT
            if str == "OK\n" {
                logger.debug("set timeout ok")

                currentTimeout = pendingTimeout

                // OK
            } else {
                logger.debug("set timeout fail \(str)")
                // FAIL
            }

        default:
            // case TAG_TASK_COMMAND:
            // got reply from task command

            logger.verbose("TAGTAGTAGTAG: \(tag)")

            // dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                if self.isTaskCommandTag(taskCommandTag: tag) {
                    if let (_taskId, _tag) = self.parseTaskCommandTag(taskCommandTag: tag) {

                        logger.verbose("\(tag): got reply from task command")
                        logger.verbose("\(tag): taskId: \(_taskId), _tag: \(_tag)")

                        if let taskId = self.matchAndGetTestIdFromResponse(str) {
                            logger.verbose("\(tag): TASK ID: \(taskId)")

                            //logger.verbose("\(taskDelegateDictionary.count)")
                            //logger.verbose("\(taskDelegateDictionary.indexForKey(1))")

                            if let taskDelegate = self.taskDelegateDictionary[taskId] {
                                logger.verbose("\(tag): TASK DELEGATE: \(taskDelegate)")

                                logger.debug("CALLING DELEGATE METHOD of \(taskDelegate), withResponse: \(str), taskId: \(taskId), tag: \(tag), _tag: \(_tag)")

                                // call delegate method // TODO: dispatch delegate methods with dispatch queue of delegate
                                taskDelegate.controlConnection(self, didReceiveTaskResponse: str, withTaskId: taskId, tag: _tag)
                            }
                        }
                    }
                }
            // }
        }
    }

    ///
    @objc func socket(sock: GCDAsyncSocket!, didReadPartialDataOfLength partialLength: UInt, tag: Int) {
        logger.verbose("didReadPartialDataOfLength \(partialLength), tag: \(tag)")
    }

    ///
    @objc func socket(sock: GCDAsyncSocket!, didWriteDataWithTag tag: Int) {
        logger.verbose("didWriteDataWithTag \(tag)")
    }

    ///
    @objc func socket(sock: GCDAsyncSocket!, didWritePartialDataOfLength partialLength: UInt, tag: Int) {
        logger.verbose("didWritePartialDataOfLength \(partialLength), tag: \(tag)")
    }

    ///
    @objc func socket(sock: GCDAsyncSocket!, shouldTimeoutReadWithTag tag: Int, elapsed: NSTimeInterval, bytesDone length: UInt) -> NSTimeInterval {
        logger.verbose("shouldTimeoutReadWithTag \(tag), elapsed: \(elapsed), bytesDone: \(length)")

        // if (tag < TAG_TASK_COMMAND) {
        if isTaskCommandTag(taskCommandTag: tag) {
            //let taskId = UInt(-tag + TAG_TASK_COMMAND)
            if let (taskId, _tag) = parseTaskCommandTag(taskCommandTag: tag) {

                logger.verbose("TASK ID: \(taskId)")

                if let taskDelegate = taskDelegateDictionary[taskId] {
                    logger.verbose("TASK DELEGATE: \(taskDelegate)")

                    // call delegate method // TODO: dispatch delegate methods with dispatch queue of delegate
                    taskDelegate.controlConnection(self, didReceiveTimeout: elapsed, withTaskId: taskId, tag: _tag)
                    logger.debug("!!! AFTER DID_RECEIVE_TIMEOUT !!!!")
                }
            }
        }

        // return -1 // always let this timeout
        return 10000 // extend timeout ... because of the weird timeout handling of GCDAsyncSocket (socket would close)
    }

    ///
    @objc func socket(sock: GCDAsyncSocket!, shouldTimeoutWriteWithTag tag: Int, elapsed: NSTimeInterval, bytesDone length: UInt) -> NSTimeInterval {
        logger.verbose("shouldTimeoutReadWithTag \(tag), elapsed: \(elapsed), bytesDone: \(length)")

        // if (tag < TAG_TASK_COMMAND) {
        if isTaskCommandTag(taskCommandTag: tag) {
            //let taskId = UInt(-tag + TAG_TASK_COMMAND)
            if let (taskId, _tag) = parseTaskCommandTag(taskCommandTag: tag) {

                logger.verbose("TASK ID: \(taskId)")

                if let taskDelegate = taskDelegateDictionary[taskId] {
                    logger.verbose("TASK DELEGATE: \(taskDelegate)")

                    // call delegate method // TODO: dispatch delegate methods with dispatch queue of delegate
                    taskDelegate.controlConnection(self, didReceiveTimeout: elapsed, withTaskId: taskId, tag: _tag)
                }
            }
        }

        //return -1 // always let this timeout
        return 10000 // extend timeout ... because of the weird timeout handling of GCDAsyncSocket (socket would close)
    }

    ///
    @objc func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        connected = false

        if err == nil {
            logger.debug("QOS CC: socket closed by server after sending QUIT")
            return // if the server closed the connection error is nil (this happens after sending QUIT to the server)
        }

        logger.debug("QOS CC: disconnected with error \(err)")
        // TODO: fail!
    }

}
