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

class QOSControlConnectionTaskWeakObserver: NSObject {
    weak var delegate: QOSControlConnectionTaskDelegate?
    
    init(_ delegate: QOSControlConnectionTaskDelegate) {
        self.delegate = delegate
    }
}

class QOSControlConnection: NSObject {

    internal let TAG_GREETING = -1
    internal let TAG_FIRST_ACCEPT = -2
    internal let TAG_TOKEN = -3
    //internal let TAG_OK = -4
    internal let TAG_SECOND_ACCEPT = -4

    internal let TAG_SET_TIMEOUT = -10

    internal let TAG_TASK_COMMAND = -100

    //

    ///
    weak var delegate: QOSControlConnectionDelegate?

    ///
    var connected = false

    ///
    internal let testToken: String

    ///
    internal let connectCountDownLatch = CountDownLatch()

    ///
    internal let socketQueue = DispatchQueue(label: "com.specure.rmbt.controlConnectionSocketQueue")
    
    internal let mutableQueue = DispatchQueue(label: "com.specure.rmbt.mutableQueue")
    ///
    internal lazy var qosControlConnectionSocket: GCDAsyncSocket = GCDAsyncSocket(delegate: self, delegateQueue: socketQueue)

    ///
    internal var taskDelegateDictionary: [UInt: [QOSControlConnectionTaskWeakObserver]] = [:]

    ///
    internal var pendingTimeout: Double = 0
    internal var currentTimeout: Double = 0

    //

    deinit {
        defer {
            taskDelegateDictionary = [:]
            qosControlConnectionSocket.delegate = nil
            qosControlConnectionSocket.disconnect()
        }
    }
    ///
    init(testToken: String) {
        self.testToken = testToken

        super.init()

        Log.logger.verbose("control connection created")
    }

// MARK: connection handling

    ///
    func connect(_ host: String, onPort port: UInt16) -> Bool {
        return connect(host, onPort: port, withTimeout: QOS_CONTROL_CONNECTION_TIMEOUT_NS)
    }

    ///
    func connect(_ host: String, onPort port: UInt16, withTimeout timeout: UInt64) -> Bool {
        let connectTimeout = nsToSec(timeout)

        do {
            qosControlConnectionSocket.setupSocket()
            try qosControlConnectionSocket.connect(toHost: host, onPort: port, withTimeout: connectTimeout)
        } catch {
            // there was an error
            Log.logger.verbose("connection error \(error)")
        }

        _ = connectCountDownLatch.await(timeout)
        
        return connected
    }

    ///
    func disconnect() {
        // send quit
        Log.logger.debug("QUIT QUIT QUIT QUIT QUIT")

        self.writeLine("QUIT", withTimeout: QOS_CONTROL_CONNECTION_TIMEOUT_SEC, tag: -1) // don't bother with the tag, don't need read after this operation
        qosControlConnectionSocket.disconnectAfterWriting()
        // qosControlConnectionSocket.disconnectAfterReadingAndWriting()
    }

// MARK: commands

    ///
    func setTimeout(_ timeout: UInt64) {
        // Log.logger.debug("SET TIMEOUT: \(timeout)")

        // timeout is in nanoseconds -> convert to ms
        var msTimeout = nsToMs(timeout)

        // if msTimeout is lower than 15 seconds, increase it
        if msTimeout < 15_000 {
            msTimeout = 15_000
        }

        if currentTimeout == msTimeout {
            Log.logger.debug("skipping change of control connection timeout because old value = new value")
            return // skip if old == new timeout
        }

        pendingTimeout = msTimeout

        // Log.logger.debug("REQUEST CONN TIMEOUT \(msTimeout)")
        writeLine("REQUEST CONN TIMEOUT \(msTimeout)", withTimeout: QOS_CONTROL_CONNECTION_TIMEOUT_SEC, tag: TAG_SET_TIMEOUT)
        readLine(TAG_SET_TIMEOUT, withTimeout: QOS_CONTROL_CONNECTION_TIMEOUT_SEC)
    }

// MARK: control connection delegate methods

    func clearObservers() {
        for (_, arrayOfObservers) in taskDelegateDictionary.enumerated() {
            var observers = arrayOfObservers.value
            for observer in arrayOfObservers.value {
                if observer.delegate == nil {
                    if let index = observers.firstIndex(of: observer) {
                        observers.remove(at: index)
                    }
                }
            }
            if observers.count == 0 {
                taskDelegateDictionary.removeValue(forKey: arrayOfObservers.key)
            }
        }
    }
    
    ///
    func registerTaskDelegate(_ delegate: QOSControlConnectionTaskDelegate, forTaskId taskId: UInt) {
        self.mutableQueue.sync {
            var observers: [QOSControlConnectionTaskWeakObserver]? = taskDelegateDictionary[taskId]
            if observers == nil {
                observers = []
            }
            
            observers?.append(QOSControlConnectionTaskWeakObserver(delegate))
            taskDelegateDictionary[taskId] = observers
            self.clearObservers()
            Log.logger.debug("registerTaskDelegate: \(taskId), delegate: \(delegate)")
        }
    }

    ///
    func unregisterTaskDelegate(_ delegate: QOSControlConnectionTaskDelegate, forTaskId taskId: UInt) {
        self.mutableQueue.sync {
            if let tempObservers = taskDelegateDictionary[taskId] {
                var observers = tempObservers
                if let index = observers.firstIndex(where: { (observer) -> Bool in
                    return observer.delegate! === delegate
                }) {
                    observers.remove(at: index)
                    Log.logger.debug("unregisterTaskDelegate: \(taskId), delegate: \(delegate)")
                }
                if observers.count == 0 {
                    taskDelegateDictionary[taskId] = nil
                }
                else {
                    taskDelegateDictionary[taskId] = observers
                }
            }
            else {
                Log.logger.debug("TaskDelegate: \(taskId) Not found")
            }
            self.clearObservers()
        }
    }

// MARK: task command methods

    // TODO: use closure instead of delegate methods
    /// command should not contain \n, will be added inside this method
    func sendTaskCommand(_ command: String, withTimeout timeout: TimeInterval, forTaskId taskId: UInt, tag: Int) {
        /* if (!qosControlConnectionSocket.isConnected) {
            Log.logger.error("control connection is closed, sendTaskCommand won't work!")
        } */

        let _command = command + " +ID\(taskId)"

        let t = createTaskCommandTag(forTaskId: taskId, tag: tag)
        Log.logger.verbose("SENDTASKCOMMAND: (taskId: \(taskId), tag: \(tag)) -> \(t) (\(String(t, radix: 2)))")

        // write command
        writeLine(_command, withTimeout: timeout, tag: t)

        // and then read? // TODO: or use thread with looped readLine?
        readLine(t, withTimeout: timeout)
    }

    /// command should not contain \n, will be added inside this method
    func sendTaskCommand(_ command: String, withTimeout timeout: TimeInterval, forTaskId taskId: UInt) {
        sendTaskCommand(command, withTimeout: timeout, forTaskId: taskId, tag: TAG_TASK_COMMAND)
    }

// MARK: convenience methods

    ///
    internal func writeLine(_ line: String, withTimeout timeout: TimeInterval, tag: Int) {
        qosControlConnectionSocket.writeLine(line: line, withTimeout: timeout, tag: tag)
    }

    ///
    internal func readLine(_ tag: Int, withTimeout timeout: TimeInterval) {
        qosControlConnectionSocket.readLine(tag: tag, withTimeout: timeout)
    }

// MARK: other methods

    ///
    internal func createTaskCommandTag(forTaskId taskId: UInt, tag: Int) -> Int {
        // bitfield: 0111|aaaa_aaaa_aaaa|bbbb_bbbb_bbbb_bbbb

        var bitfield: UInt32 = 0x7

        bitfield = bitfield << 12

        bitfield = bitfield + (UInt32(abs(tag)) & 0x0000_0FFF)

        bitfield = bitfield << 16

        bitfield = bitfield + (UInt32(taskId) & 0x0000_FFFF)

        // Log.logger.verbose("created BITFIELD for taskId: \(taskId), tag: \(tag) -> \(String(bitfield, radix: 2))")
        // Log.logger.verbose("created BITFIELD for taskId: \(taskId), tag: \(tag) -> \(String(Int(bitfield), radix: 2))")

        return Int(bitfield)
    }

    ///
    internal func parseTaskCommandTag(taskCommandTag commandTag: Int) -> (taskId: UInt, tag: Int)? {
        let _commandTag = UInt(commandTag)

        if !isTaskCommandTag(taskCommandTag: commandTag) {
            return nil // not a valid task command tag
        }

        let taskId: UInt = _commandTag & 0x0000_FFFF
        let tag = Int((_commandTag & 0x0FFF_0000) >> 16)

        Log.logger.verbose("BITFIELD2: \(commandTag) -> (taskId: \(taskId), tag: \(tag))")

        return (taskId, tag)
    }

    ///
    internal func isTaskCommandTag(taskCommandTag commandTag: Int) -> Bool {
        if commandTag < 0 {
            return false
        }

        return UInt(commandTag) & 0x7000_0000 == 0x7000_0000
    }

    ///
    internal func matchAndGetTestIdFromResponse(_ response: String) -> UInt? {
        do {
            let regex = try NSRegularExpression(pattern: "\\+ID(\\d*)", options: [])

            if let match = regex.firstMatch(in: response, options: [], range: NSRange(location: 0, length: response.count)) {
                // println(match)

                if match.numberOfRanges > 0 {
                    let idStr = (response as NSString).substring(with: match.range(at: 1))

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
    func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        Log.logger.verbose("connected to host \(host) on port \(port)")

        // control connection to qos server uses tls
        sock.startTLS(QOS_TLS_SETTINGS)
    }

    func socket(_ sock: GCDAsyncSocket, didReceive trust: SecTrust, completionHandler: @escaping ((Bool) -> Void)) {
        Log.logger.verbose("DID RECEIVE TRUST")
        completionHandler(true)
    }

    ///
    @objc func socketDidSecure(_ sock: GCDAsyncSocket) {
        Log.logger.verbose("socketDidSecure")

        // tls connection has been established, start with QTP handshake
        readLine(TAG_GREETING, withTimeout: QOS_CONTROL_CONNECTION_TIMEOUT_SEC)
    }

    ///
    @objc func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        Log.logger.verbose("didReadData \(data) with tag \(tag)")

        let str: String = SocketUtils.parseResponseToString(data)!

        Log.logger.verbose("didReadData \(str)")

        switch tag {
        case TAG_GREETING:
            // got greeting
            Log.logger.verbose("got greeting")

            // read accept
            self.readLine(TAG_FIRST_ACCEPT, withTimeout: QOS_CONTROL_CONNECTION_TIMEOUT_SEC)

        case TAG_FIRST_ACCEPT:
            // got accept
            Log.logger.verbose("got accept")

            // send token
            let tokenCommand = "TOKEN \(testToken)\n"
            self.writeLine(tokenCommand, withTimeout: QOS_CONTROL_CONNECTION_TIMEOUT_SEC, tag: TAG_TOKEN)

            // read token response
            self.readLine(TAG_TOKEN, withTimeout: QOS_CONTROL_CONNECTION_TIMEOUT_SEC)

        case TAG_TOKEN:
            // response from token command
            Log.logger.verbose("got ok")

            // read second accept
            self.readLine(TAG_SECOND_ACCEPT, withTimeout: QOS_CONTROL_CONNECTION_TIMEOUT_SEC)

        case TAG_SECOND_ACCEPT:
            // got second accept
            Log.logger.verbose("got second accept")

            // now connection is ready
            Log.logger.verbose("CONNECTION READY")

            connected = true // set connected to true to unlock
            connectCountDownLatch.countDown()

            // call delegate method // TODO: on which queue?
            self.delegate?.controlConnectionReadyToUse(self)

            //
        case TAG_SET_TIMEOUT:
            // return from REQUEST CONN TIMEOUT
            if str == "OK\n" {
                Log.logger.debug("set timeout ok")

                currentTimeout = pendingTimeout

                // OK
            } else {
                Log.logger.debug("set timeout fail \(str)")
                // FAIL
            }

        default:
            // case TAG_TASK_COMMAND:
            // got reply from task command

            Log.logger.verbose("TAGTAGTAGTAG: \(tag)")

            // dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                if self.isTaskCommandTag(taskCommandTag: tag) {
                    if let (_taskId, _tag) = self.parseTaskCommandTag(taskCommandTag: tag) {

                        Log.logger.verbose("\(tag): got reply from task command")
                        Log.logger.verbose("\(tag): taskId: \(_taskId), _tag: \(_tag)")

                        if let taskId = self.matchAndGetTestIdFromResponse(str) {
                            Log.logger.verbose("\(tag): TASK ID: \(taskId)")

                            //Log.logger.verbose("\(taskDelegateDictionary.count)")
                            //Log.logger.verbose("\(taskDelegateDictionary.indexForKey(1))")

                            if let observers = self.taskDelegateDictionary[taskId] {
                                for observer in observers {
                                    Log.logger.verbose("\(tag): TASK DELEGATE: \(String(describing: observer.delegate))")

                                    Log.logger.debug("CALLING DELEGATE METHOD of \(String(describing: observer.delegate)), withResponse: \(str), taskId: \(taskId), tag: \(tag), _tag: \(_tag)")

                                    // call delegate method // TODO: dispatch delegate methods with dispatch queue of delegate
                                    observer.delegate?.controlConnection(self, didReceiveTaskResponse: str, withTaskId: taskId, tag: _tag)
                                }
                            }
                        }
                    }
                }
            // }
        }
    }

    ///
    @objc func socket(_ sock: GCDAsyncSocket, didReadPartialDataOfLength partialLength: UInt, tag: Int) {
        Log.logger.verbose("didReadPartialDataOfLength \(partialLength), tag: \(tag)")
    }

    ///
    @objc func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        Log.logger.verbose("didWriteDataWithTag \(tag)")
    }

    ///
    @objc func socket(_ sock: GCDAsyncSocket, didWritePartialDataOfLength partialLength: UInt, tag: Int) {
        Log.logger.verbose("didWritePartialDataOfLength \(partialLength), tag: \(tag)")
    }

    ///
    @objc func socket(_ sock: GCDAsyncSocket, shouldTimeoutReadWithTag tag: Int, elapsed: TimeInterval, bytesDone length: UInt) -> TimeInterval {
        Log.logger.verbose("shouldTimeoutReadWithTag \(tag), elapsed: \(elapsed), bytesDone: \(length)")

        // if (tag < TAG_TASK_COMMAND) {
        if isTaskCommandTag(taskCommandTag: tag) {
            //let taskId = UInt(-tag + TAG_TASK_COMMAND)
            if let (taskId, _tag) = parseTaskCommandTag(taskCommandTag: tag) {

                Log.logger.verbose("TASK ID: \(taskId)")

                if let observers = taskDelegateDictionary[taskId] {
                    for observer in observers {
                        Log.logger.verbose("TASK DELEGATE: \(String(describing: observer.delegate))")

                        // call delegate method // TODO: dispatch delegate methods with dispatch queue of delegate
                        observer.delegate?.controlConnection(self, didReceiveTimeout: elapsed, withTaskId: taskId, tag: _tag)
                        Log.logger.debug("!!! AFTER DID_RECEIVE_TIMEOUT !!!!")
                    }
                }
            }
        }

        // return -1 // always let this timeout
        return 10000 // extend timeout ... because of the weird timeout handling of GCDAsyncSocket (socket would close)
    }

    ///
    @objc func socket(_ sock: GCDAsyncSocket, shouldTimeoutWriteWithTag tag: Int, elapsed: TimeInterval, bytesDone length: UInt) -> TimeInterval {
        Log.logger.verbose("shouldTimeoutReadWithTag \(tag), elapsed: \(elapsed), bytesDone: \(length)")

        // if (tag < TAG_TASK_COMMAND) {
        if isTaskCommandTag(taskCommandTag: tag) {
            //let taskId = UInt(-tag + TAG_TASK_COMMAND)
            if let (taskId, _tag) = parseTaskCommandTag(taskCommandTag: tag) {

                Log.logger.verbose("TASK ID: \(taskId)")

                if let observers = taskDelegateDictionary[taskId] {
                    for observer in observers {
                        Log.logger.verbose("TASK DELEGATE: \(String(describing: observer.delegate))")

                        // call delegate method // TODO: dispatch delegate methods with dispatch queue of delegate
                        observer.delegate?.controlConnection(self, didReceiveTimeout: elapsed, withTaskId: taskId, tag: _tag)
                    }
                }
            }
        }

        //return -1 // always let this timeout
        return 10000 // extend timeout ... because of the weird timeout handling of GCDAsyncSocket (socket would close)
    }

    ///
    @objc func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?) {
        connected = false

        if err == nil {
            Log.logger.debug("QOS CC: socket closed by server after sending QUIT")
            return // if the server closed the connection error is nil (this happens after sending QUIT to the server)
        }

        Log.logger.debug("QOS CC: disconnected with error \(String(describing: err))")
        // TODO: fail!
    }

}
