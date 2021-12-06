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
typealias TracerouteTestExecutor = QOSTracerouteTestExecutor<QOSTracerouteTest>

///
class QOSTracerouteTestExecutor<T: QOSTracerouteTest>: QOSTestExecutorClass<T> {

    fileprivate let RESULT_TRACEROUTE_HOST      = "traceroute_objective_host"
    fileprivate let RESULT_TRACEROUTE_DETAILS   = "traceroute_result_details"
    fileprivate let RESULT_TRACEROUTE_TIMEOUT   = "traceroute_objective_timeout"
    fileprivate let RESULT_TRACEROUTE_STATUS    = "traceroute_result_status"
    fileprivate let RESULT_TRACEROUTE_MAX_HOPS  = "traceroute_objective_max_hops"
    fileprivate let RESULT_TRACEROUTE_HOPS      = "traceroute_result_hops"

    //

    ///
    fileprivate var pingUtilDelegateBridge: PingUtilDelegateBridge!

    ///
    fileprivate let timer = GCDTimer()

    ///
    fileprivate var pingUtil: PingUtil!

    ///
    fileprivate var ttl: UInt8 = 1

    ///
    fileprivate var ttlCurrentTry: UInt8 = 0

    ///
    fileprivate var hopDetailArray = [[String: Any]]()

    ///
    fileprivate var currentHopDetail = HopDetail()

    ///
    fileprivate var currentPingStartTimeTicks: UInt64!

    ///
    override init(controlConnection: QOSControlConnection?, delegateQueue: DispatchQueue, testObject: T, speedtestStartTime: UInt64) {
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
                // Log.logger.debug("executing run loop")
                RunLoop.current.run(mode: RunLoop.Mode.default, before: Date.distantFuture)
                // Log.logger.debug("run loop ran")
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
    fileprivate func failWithMaxHopsExceeded() {
        stop()

        // TODO: failure

        testResult.set(RESULT_TRACEROUTE_STATUS,    value: "MAX_HOPS_EXCEEDED")
        testResult.set(RESULT_TRACEROUTE_HOPS,      number: ttl)

        callFinishCallback()
    }

    ///
    fileprivate func ping() {
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
        currentPingStartTimeTicks = UInt64.getCurrentTimeTicks()

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
    fileprivate func stop() {
        timer.stop()

        pingUtil = nil
    }

    ///
    fileprivate func appendLastHopDetail() {
        // TODO: reverse dns query for ip addresses?

        hopDetailArray.append(currentHopDetail.getAsDictionary())
    }

}

///
extension QOSTracerouteTestExecutor: PingUtilSwiftDelegate {

    ///
    func pingUtil(_ pingUtil: PingUtil, didStartWithAddress address: Data) {
        // start with test
        ping()
    }

    ///
    func pingUtil(_ pingUtil: PingUtil, didSendPacket packet: Data) {
        qosLog.debug("ping util sent packet: \(packet)")
    }

    ///
    func pingUtil(_ pingUtil: PingUtil, didReceivePingResponsePacket packet: Data, withType type: UInt8, fromIp: String) {
        qosLog.debug("received response packet with type \(type)! stopping timer")

        // stop timer
        timer.stop()

        // fill current hop detail
        currentHopDetail.fromIp = fromIp
        currentHopDetail.addTry(UInt64.getTimeDifferenceInNanoSeconds(currentPingStartTimeTicks))

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
    func pingUtil(_ pingUtil: PingUtil, didFailWithError error: Error!) {
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
    fileprivate func resolveIP(_ host: String) -> String? {
        let host = CFHostCreateWithName(nil, host as CFString).takeRetainedValue()

        CFHostStartInfoResolution(host, .addresses, nil)

        var success: DarwinBoolean = false
        let addresses = CFHostGetAddressing(host, &success)!.takeUnretainedValue() as NSArray // !

        for addr in addresses {
            let theAddress = addr as! Data
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))

            if getnameinfo((theAddress as NSData).bytes.bindMemory(to: sockaddr.self, capacity: theAddress.count), socklen_t(theAddress.count), &hostname, socklen_t(hostname.count), nil, 0, NI_NUMERICHOST) == 0 {
                if let numAddress = String(validatingUTF8: hostname) {
                    if (numAddress as NSString).isValidIPv4() { // traceroute currently only supports ipv4
                        return numAddress
                    }
                }
            }
        }

        return nil
    }

}
