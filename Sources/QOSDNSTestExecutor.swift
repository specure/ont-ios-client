//
//  QOSDNSTestExecutor.swift
//  RMBT
//
//  Created by Benjamin Pucher on 29.01.15.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

import Foundation
import RMBTClient.Private

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
    override init(controlConnection: QOSControlConnection, delegateQueue: dispatch_queue_t, testObject: T, speedtestStartTime: UInt64) {
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
    private func try_afterDNSResolution(startTimeTicks: UInt64, responseObj: DNSRecordClass?, error: NSError?) {
        do {
            try afterDNSResolution(startTimeTicks, responseObj: responseObj)
        } catch {
            testDidFail()
        }
    }

    ///
    private func afterDNSResolution(startTimeTicks: UInt64, responseObj: DNSRecordClass?) throws {

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
                            resultRecord[RESULT_DNS_ADDRESS] = jsonValueOrNull(response.ipAddress)
                        case kDNSServiceType_CNAME:
                            resultRecord[RESULT_DNS_ADDRESS] = jsonValueOrNull(response.ipAddress)
                        case kDNSServiceType_MX:
                            resultRecord[RESULT_DNS_ADDRESS] = jsonValueOrNull(response.ipAddress)
                            resultRecord[RESULT_DNS_PRIORITY] = "\(response.mxPreference!)"
                        case kDNSServiceType_AAAA:
                            resultRecord[RESULT_DNS_ADDRESS] = jsonValueOrNull(response.ipAddress)
                        default:
                            qosLog.debug("unknown result record type \(response.qType), skipping")
                    }

                    resultRecord[RESULT_DNS_TTL] = "\(response.ttl)"

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
