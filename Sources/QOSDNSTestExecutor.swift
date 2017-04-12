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
import RMBTClientPrivate

///
typealias DNSTestExecutor = QOSDNSTestExecutor<QOSDNSTest>

///
class QOSDNSTestExecutor<T: QOSDNSTest>: QOSTestExecutorClass<T> {

    fileprivate let RESULT_DNS_STATUS           = "dns_result_status"
    fileprivate let RESULT_DNS_ENTRY            = "dns_result_entries"
    fileprivate let RESULT_DNS_TTL              = "dns_result_ttl"
    fileprivate let RESULT_DNS_ADDRESS          = "dns_result_address"
    fileprivate let RESULT_DNS_PRIORITY         = "dns_result_priority"
    fileprivate let RESULT_DNS_DURATION         = "dns_result_duration"
    fileprivate let RESULT_DNS_QUERY            = "dns_result_info"
    fileprivate let RESULT_DNS_RESOLVER         = "dns_objective_resolver"
    fileprivate let RESULT_DNS_HOST             = "dns_objective_host"
    fileprivate let RESULT_DNS_RECORD           = "dns_objective_dns_record"
    fileprivate let RESULT_DNS_ENTRIES_FOUND    = "dns_result_entries_found"
    fileprivate let RESULT_DNS_TIMEOUT          = "dns_objective_timeout"

    //

    ///
    override init(controlConnection: QOSControlConnection, delegateQueue: DispatchQueue, testObject: T, speedtestStartTime: UInt64) {
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

    ///
    override func executeTest() {

        if let host = testObject.host {
            qosLog.debug("EXECUTING DNS TEST")

            let startTimeTicks = getCurrentTimeTicks()

            // do dns query
            // TODO: improve

            // TODO: check if record is supported (in map)

            // do {
                if let resolver = self.testObject.resolver {
                    /* try */ DNSClient.queryNameserver(resolver, serverPort: 53, forName: host, recordType: self.testObject.record!, success: { responseObj in
                        self.try_afterDNSResolution(startTimeTicks, responseObj: responseObj, error: nil)
                    }, failure: { error in
                        self.try_afterDNSResolution(startTimeTicks, responseObj: nil, error: error)
                    })
                } else {
                    /* try */ DNSClient.query(host, recordType: self.testObject.record!, success: { responseObj in
                        self.try_afterDNSResolution(startTimeTicks, responseObj: responseObj, error: nil)
                    }, failure: { error in
                        self.try_afterDNSResolution(startTimeTicks, responseObj: nil, error: error)
                    })
                }
            // } catch {
            //    testDidFail()
            // }
        }
    }

    ///
    fileprivate func try_afterDNSResolution(_ startTimeTicks: UInt64, responseObj: DNSRecordClass?, error: NSError?) {
        do {
            try afterDNSResolution(startTimeTicks, responseObj: responseObj)
        } catch {
            testDidFail()
        }
    }

    ///
    fileprivate func afterDNSResolution(_ startTimeTicks: UInt64, responseObj: DNSRecordClass?) throws {

        self.testResult.set(self.RESULT_DNS_DURATION, number: getTimeDifferenceInNanoSeconds(startTimeTicks))

        //

        // testResult.set(RESULT_DNS_STATUS, value: "NOERROR") // TODO: Rcode

        //

        var resourceRecordArray = [[String: AnyObject]]()

        if let response = responseObj {

            // for response.resultRecords {

                var resultRecord = [String: AnyObject]()

                testResult.set(RESULT_DNS_STATUS, value: response.rcodeString())

                // TODO: improve this section

                if let qType = response.qType {

                    switch Int(qType) {
                        case kDNSServiceType_A:
                            resultRecord[RESULT_DNS_ADDRESS] = jsonValueOrNull(response.ipAddress as String? as AnyObject?) 
                        case kDNSServiceType_CNAME:
                            resultRecord[RESULT_DNS_ADDRESS] = jsonValueOrNull(response.ipAddress as AnyObject?)
                        case kDNSServiceType_MX:
                            resultRecord[RESULT_DNS_ADDRESS] = jsonValueOrNull(response.ipAddress as AnyObject?)
                            resultRecord[RESULT_DNS_PRIORITY] = "\(response.mxPreference!)" as AnyObject?
                        case kDNSServiceType_AAAA:
                            resultRecord[RESULT_DNS_ADDRESS] = jsonValueOrNull(response.ipAddress as AnyObject?)
                        default:
                            qosLog.debug("unknown result record type \(response.qType), skipping")
                    }

                    resultRecord[RESULT_DNS_TTL] = "\(response.ttl)" as AnyObject?

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
        testResult.set(RESULT_DNS_QUERY, value: "OK")

        super.testDidSucceed()
    }

    ///
    override func testDidTimeout() {
        testResult.set(RESULT_DNS_QUERY, value: "TIMEOUT")

        testResult.set(RESULT_DNS_ENTRY, value: /* [] as NSArray */nil)
        testResult.set(RESULT_DNS_ENTRIES_FOUND, value: 0)

        super.testDidTimeout()
    }

    ///
    override func testDidFail() {
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
