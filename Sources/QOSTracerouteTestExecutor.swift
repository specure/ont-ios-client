//
//  QOSTracerouteTestExecutor.swift
//  RMBT
//
//  Created by Benjamin Pucher on 20.01.15.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

import Foundation

///
typealias TracerouteTestExecutor = QOSTracerouteTestExecutor<QOSTracerouteTest>

///
class QOSTracerouteTestExecutor<T: QOSTracerouteTest>: QOSTestExecutorClass<T> {

    private let RESULT_TRACEROUTE_HOST      = "traceroute_objective_host"
    private let RESULT_TRACEROUTE_DETAILS   = "traceroute_result_details"
    private let RESULT_TRACEROUTE_TIMEOUT   = "traceroute_objective_timeout"
    private let RESULT_TRACEROUTE_STATUS    = "traceroute_result_status"
    private let RESULT_TRACEROUTE_MAX_HOPS  = "traceroute_objective_max_hops"
    private let RESULT_TRACEROUTE_HOPS      = "traceroute_result_hops"

    //

    ///
    private var pingUtilDelegateBridge: PingUtilDelegateBridge!

    ///
    private let timer = GCDTimer()

    ///
    private var pingUtil: PingUtil!

    ///
    private var ttl: UInt8 = 1

    ///
    private var ttlCurrentTry: UInt8 = 0

    ///
    private var hopDetailArray = [[String: AnyObject]]()

    ///
    private var currentHopDetail = HopDetail()

    ///
    private var currentPingStartTimeTicks: UInt64!

    ///
    override init(controlConnection: QOSControlConnection, delegateQueue: dispatch_queue_t, testObject: T, speedtestStartTime: UInt64) {
        super.init(controlConnection: controlConnection, delegateQueue: delegateQueue, testObject: testObject, speedtestStartTime: speedtestStartTime)

        pingUtilDelegateBridge = PingUtilDelegateBridge(obj: self)

        // setup timer
        timer.interval = testObject.noResponseTimeout
        timer.timerCallback = pingTimeout
    }

    ///
    override func startTest() {
        super.startTest()

        testResult.set(RESULT_TRACEROUTE_HOST,      value: testObject.host)
        testResult.set(RESULT_TRACEROUTE_MAX_HOPS,  number: testObject.maxHops)
        testResult.set(RESULT_TRACEROUTE_TIMEOUT,   number: testObject.timeout)
    }

    ///
    override func executeTest() {

        if let host = testObject.host {
            qosLog.debug("EXECUTING TRACEROUTE TEST")

            var resolvedHost: String = host

            // resolve ip if host contains hostname
            if !(host as NSString).isValidIPv4() { // traceroute currently only supports ipv4
                if let ip = resolveIP(host) {
                    resolvedHost = ip
                }
            }

            // host can be ip or hostname
            qosLog.debug("HOST: \(host), resolved: \(resolvedHost)")

            // strange bug if compiling on command line '(host: String!) -> PingUtil' is not convertible to '(host: String!) -> PingUtil!'
            pingUtil = PingUtil(host: resolvedHost)

            if pingUtil == nil {
                testDidFail()
                return
            }

            pingUtil.delegate = pingUtilDelegateBridge

            pingUtil.start()

            repeat { // needed for CFRunLoop things...
                // logger.debug("executing run loop")
                NSRunLoop.currentRunLoop().runMode(NSDefaultRunLoopMode, beforeDate: NSDate.distantFuture())
                // logger.debug("run loop ran")
            } while self.pingUtil != nil
        }
    }

    ///
    override func testDidSucceed() {
        stop()

        //log(.Debug, "\(hopDetailArray)")

        testResult.set(RESULT_TRACEROUTE_STATUS,    value: "OK")
        testResult.set(RESULT_TRACEROUTE_HOPS,      number: ttl)
        testResult.set(RESULT_TRACEROUTE_DETAILS,   value: hopDetailArray as NSArray) // cast does not work if HopDetail is a struct

        super.testDidSucceed()
    }

    ///
    override func testDidTimeout() {
        stop()

        testResult.set(RESULT_TRACEROUTE_STATUS,    value: "TIMEOUT")
        testResult.set(RESULT_TRACEROUTE_HOPS,      number: ttl)
        testResult.set(RESULT_TRACEROUTE_DETAILS,   value: hopDetailArray as NSArray) // cast does not work if HopDetail is a struct

        super.testDidTimeout()
    }

    ///
    override func testDidFail() {
        stop()

        testResult.set(RESULT_TRACEROUTE_STATUS,    value: "ERROR")
        testResult.set(RESULT_TRACEROUTE_HOPS,      number: 0)
        testResult.set(RESULT_TRACEROUTE_DETAILS,   value: nil)

        super.testDidFail()
    }

    ///
    override func needsControlConnection() -> Bool {
        return false
    }

// MARK: custom methods

    ///
    private func failWithMaxHopsExceeded() {
        stop()

        // TODO: failure

        testResult.set(RESULT_TRACEROUTE_STATUS,    value: "MAX_HOPS_EXCEEDED")
        testResult.set(RESULT_TRACEROUTE_HOPS,      number: ttl)

        callFinishCallback()
    }

    ///
    private func ping() {
        ttlCurrentTry += 1

        if ttlCurrentTry > testObject.triesPerTTL {
            ttl += 1
            ttlCurrentTry = 1

            // append last hop detail (if not nil)
            appendLastHopDetail()

            // create new hop detail
            currentHopDetail = HopDetail()
        }

        if ttl > testObject.maxHops {
            // stop with failure
            failWithMaxHopsExceeded()
        }

        qosLog.debug("pinging with ttl: \(ttl)/\(testObject.maxHops), try: \(ttlCurrentTry)/\(testObject.triesPerTTL)")

        // store start nanoseconds
        currentPingStartTimeTicks = getCurrentTimeTicks()

        // start timer
        timer.start()

        // send ping
        pingUtil.sendPing(ttl)
    }

    ///
    func pingTimeout() {
        qosLog.debug("ping timeout")

        // fill current hop detail
        currentHopDetail.fromIp = "*" // * instead of null
        currentHopDetail.addTry(UInt64(testObject.noResponseTimeout) * NSEC_PER_SEC)

        // try with next ttl
        ping()
    }

    ///
    private func stop() {
        timer.stop()

        pingUtil = nil
    }

    ///
    private func appendLastHopDetail() {
        // TODO: reverse dns query for ip addresses?

        hopDetailArray.append(currentHopDetail.getAsDictionary())
    }

}

///
extension QOSTracerouteTestExecutor: PingUtilSwiftDelegate {

    ///
    func pingUtil(pingUtil: PingUtil, didStartWithAddress address: NSData) {
        // start with test
        ping()
    }

    ///
    func pingUtil(pingUtil: PingUtil, didSendPacket packet: NSData) {
        qosLog.debug("ping util sent packet: \(packet)")
    }

    ///
    func pingUtil(pingUtil: PingUtil, didReceivePingResponsePacket packet: NSData, withType type: UInt8, fromIp: String) {
        qosLog.debug("received response packet with type \(type)! stopping timer")

        // stop timer
        timer.stop()

        // fill current hop detail
        currentHopDetail.fromIp = fromIp
        currentHopDetail.addTry(getTimeDifferenceInNanoSeconds(currentPingStartTimeTicks))

        // check for icmp reply
        if type == UInt8(kICMPTypeEchoReply) {

            // finish only after last try
            if ttlCurrentTry == testObject.triesPerTTL {
                appendLastHopDetail() // need to append last hop detail here because ping() isn't called anymore
                return testDidSucceed()
            }
        }/* else if (<ttl exceeded, or other error>) {
            ping()
        } */

        ping()
    }

    ///
    func pingUtil(pingUtil: PingUtil, didFailWithError error: NSError!) {
        qosLog.debug("ping util did fail with error!")

        // test failed, TODO: set in result dictionary

        // failWithFatalError()
        testDidFail()
    }

}

// MARK: IP resolving

///
extension QOSTracerouteTestExecutor {

    ///
    private func resolveIP(host: String) -> String? {
        let host = CFHostCreateWithName(nil, host).takeRetainedValue()

        CFHostStartInfoResolution(host, .Addresses, nil)

        var success: DarwinBoolean = false
        let addresses = CFHostGetAddressing(host, &success)!.takeUnretainedValue() as NSArray // !

        for addr in addresses {
            let theAddress = addr as! NSData
            var hostname = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)

            if getnameinfo(UnsafePointer(theAddress.bytes), socklen_t(theAddress.length), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                if let numAddress = String.fromCString(hostname) {
                    if (numAddress as NSString).isValidIPv4() { // traceroute currently only supports ipv4
                        return numAddress
                    }
                }
            }
        }

        return nil
    }

}
