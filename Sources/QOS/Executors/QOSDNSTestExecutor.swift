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
#if swift(>=3.2)
    import Darwin
    import dnssd
#else
    import RMBTClientPrivate
#endif

///
typealias DNSTestExecutor = QOSDNSTestExecutor<QOSDNSTest>

///
class QOSDNSTestExecutor<T: QOSDNSTest>: QOSTestExecutorClass<T> {

    private let RESULT_DNS_STATUS           = "dns_result_status"
    private let RESULT_DNS_ENTRY            = "dns_result_entries"
    private let RESULT_DNS_TTL              = "dns_result_ttl"
    private let RESULT_DNS_ADDRESS          = "dns_result_address"
    private let RESULT_DNS_PRIORITY         = "dns_result_priority"
    private let RESULT_DNS_DURATION         = "dns_result_duration"
    private let RESULT_DNS_QUERY            = "dns_result_info"
    private let RESULT_DNS_RESOLVER         = "dns_objective_resolver"
    private let RESULT_DNS_HOST             = "dns_objective_host"
    private let RESULT_DNS_RECORD           = "dns_objective_dns_record"
    private let RESULT_DNS_ENTRIES_FOUND    = "dns_result_entries_found"
    private let RESULT_DNS_TIMEOUT          = "dns_objective_timeout"

    //

    ///
    override init(controlConnection: QOSControlConnection?, delegateQueue: DispatchQueue, testObject: T, speedtestStartTime: UInt64) {
        super.init(controlConnection: controlConnection, delegateQueue: delegateQueue, testObject: testObject, speedtestStartTime: speedtestStartTime)
    }

    ///
    override func startTest() {
        super.startTest()

        testResult.set(RESULT_DNS_RESOLVER, value: testObject.resolver ?? "Standard")
        testResult.set(RESULT_DNS_RECORD,   value: testObject.record!)
        testResult.set(RESULT_DNS_HOST,     value: testObject.host!)
        testResult.set(RESULT_DNS_TIMEOUT,  number: testObject.timeout)
    }

    var dnsClientNameserver: DNSClient?
    var dnsClientQuery: DNSClient?
    
    ///
    override func executeTest() {
        if let host = testObject.host {
            qosLog.debug("EXECUTING DNS TEST")

            let startTimeTicks = UInt64.getCurrentTimeTicks()

            // do dns query
            // TODO: improve

            // TODO: check if record is supported (in map)

            // do {
            DispatchQueue.main.async {
                if let resolver = self.testObject.resolver {
                    /* try */self.dnsClientNameserver = DNSClient.queryNameserver(resolver, serverPort: 53, forName: host, recordType: self.testObject.record!, success: { [weak self] responseObj in
                        self?.try_afterDNSResolution(startTimeTicks, responseObj: responseObj, error: nil)
                        }, failure: { [weak self] error in
                            self?.try_afterDNSResolution(startTimeTicks, responseObj: nil, error: error)
                    })
                } else {
                    /* try */ self.dnsClientQuery = DNSClient.query(host, recordType: self.testObject.record!, success: { [weak self] responseObj in
                        self?.try_afterDNSResolution(startTimeTicks, responseObj: responseObj, error: nil)
                        }, failure: { [weak self] error in
                            self?.try_afterDNSResolution(startTimeTicks, responseObj: nil, error: error)
                    })
                    // } catch {
                    //    testDidFail()
                    // }
                }
            }
            
            
        }
        else {
            testDidFail()
        }
    }

    ///
    private func try_afterDNSResolution(_ startTimeTicks: UInt64, responseObj: DNSRecordClass?, error: NSError?) {
        do {
            try afterDNSResolution(startTimeTicks, responseObj: responseObj)
        } catch {
            testDidFail()
        }
    }

    ///
    private func afterDNSResolution(_ startTimeTicks: UInt64, responseObj: DNSRecordClass?) throws {

        self.testResult.set(self.RESULT_DNS_DURATION, number: UInt64.getTimeDifferenceInNanoSeconds(startTimeTicks))

        //

        // testResult.set(RESULT_DNS_STATUS, value: "NOERROR") // TODO: Rcode

        //

        var resourceRecordArray = [[String: Any]]()

        if let response = responseObj {

            // for response.resultRecords {

                var resultRecord = [String: Any]()

                testResult.set(RESULT_DNS_STATUS, value: response.rcodeString())

                // TODO: improve this section

                if let qType = response.qType {

                    switch Int(qType) {
                        case kDNSServiceType_A:
                            resultRecord[RESULT_DNS_ADDRESS] = jsonValueOrNull(response.ipAddress as String?)
                        case kDNSServiceType_CNAME:
                            resultRecord[RESULT_DNS_ADDRESS] = jsonValueOrNull(response.ipAddress as String?)
                        case kDNSServiceType_MX:
                            resultRecord[RESULT_DNS_ADDRESS] = jsonValueOrNull(response.ipAddress as String?)
                            resultRecord[RESULT_DNS_PRIORITY] = "\(response.mxPreference!)" as AnyObject?
                        case kDNSServiceType_AAAA:
                            resultRecord[RESULT_DNS_ADDRESS] = jsonValueOrNull(response.ipAddress as String?)
                        default:
                            qosLog.debug("unknown result record type \(response.qType ?? 0), skipping")
                    }

                    resultRecord[RESULT_DNS_TTL] = "\(response.ttl!)" as AnyObject

                    resourceRecordArray.append(resultRecord)
                }

            // }
        } else /* if let err = error */ {
            // TODO: error?
            throw NSError(domain: "testtest", code: 111, userInfo: nil) // TODO
        }

        qosLog.debug("going to submit resource record array: \(resourceRecordArray)")

        testResult.set(RESULT_DNS_ENTRY, value: resourceRecordArray.count > 0 ? resourceRecordArray as NSArray : nil) // cast needed to prevent "HStore format unsupported"
        testResult.set(RESULT_DNS_ENTRIES_FOUND, value: resourceRecordArray.count)

        // callFinishCallback()
        testDidSucceed()
    }

    ///
    override func testDidSucceed() {
        self.dnsClientNameserver?.stop()
        self.dnsClientNameserver = nil
        self.dnsClientQuery?.stop()
        self.dnsClientQuery = nil
        testResult.set(RESULT_DNS_QUERY, value: "OK")

        super.testDidSucceed()
    }

    ///
    override func testDidTimeout() {
        self.dnsClientNameserver?.stop()
        self.dnsClientNameserver = nil
        self.dnsClientQuery?.stop()
        self.dnsClientQuery = nil
        testResult.set(RESULT_DNS_QUERY, value: "TIMEOUT")

        testResult.set(RESULT_DNS_ENTRY, value: /* [] as NSArray */nil)
        testResult.set(RESULT_DNS_ENTRIES_FOUND, value: 0)

        super.testDidTimeout()
    }

    ///
    override func testDidFail() {
        self.dnsClientNameserver?.stop()
        self.dnsClientNameserver = nil
        self.dnsClientQuery?.stop()
        self.dnsClientQuery = nil
        testResult.set(RESULT_DNS_QUERY, value: "ERROR")

        testResult.set(RESULT_DNS_ENTRY, value: nil)
        testResult.set(RESULT_DNS_ENTRIES_FOUND, value: 0)

        super.testDidFail()
    }

    ///
    override func needsControlConnection() -> Bool {
        return false
    }

}
