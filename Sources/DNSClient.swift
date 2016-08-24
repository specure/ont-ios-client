//
//  DNSClient.swift
//  DNSTest
//
//  Created by Benjamin Pucher on 07.03.15.
//  Copyright © 2015 Benjamin Pucher. All rights reserved.
//

import Foundation
import CocoaAsyncSocket
import RMBTClientPrivate

///
class DNSClient: NSObject, GCDAsyncUdpSocketDelegate {

    typealias DNSQuerySuccessCallback = (DNSRecordClass) -> ()
    typealias DNSQueryFailureCallback = (NSError) -> ()

    //

    ///
    private let delegateQueue = dispatch_queue_create("com.specure.dns.client", DISPATCH_QUEUE_CONCURRENT)

    ///
    private var udpSocket: GCDAsyncUdpSocket!

    //

    private var callbackSuccessMap = [String: DNSQuerySuccessCallback]()
    private var callbackFailureMap = [String: DNSQueryFailureCallback]()

    //

    ///
    private let dnsServer: String

    ///
    private let dnsPort: UInt16

    ///
    override convenience init() {
        let dnsIpDict = GetDNSIP.getdnsIPandPort()

        let host: String = dnsIpDict["host"] as! String
        let port = (dnsIpDict["port"] as! NSNumber).unsignedShortValue

        self.init(dnsServer: host, dnsPort: port)
    }

    ///
    convenience init(dnsServer: String) {
        self.init(dnsServer: dnsServer, dnsPort: 53)
    }

    ///
    required init(dnsServer: String, dnsPort: UInt16) {
        self.dnsServer = dnsServer
        self.dnsPort = dnsPort

        super.init()
        
        //

        // create udpSocket
        udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: delegateQueue)

        do {
            // bind to port
            logger.debug("- binding to port 0")

            try udpSocket.bindToPort(0)

            logger.debug("- begin receiving")

            // begin receiving
            try udpSocket.beginReceiving()
        } catch { // TODO: are there any obstacles of doing this? should we throw an exception here?
            stop()
        }
    }

    ///
    deinit {
        stop()
    }

    ///
    func stop() {
        udpSocket?.close()
        udpSocket = nil
    }

// MARK: class query methods

    ///
    class func queryNameserver(serverHost: String, serverPort: UInt16, forName qname: String, recordType: UInt16,
                               success successCallback: DNSQuerySuccessCallback, failure failureCallback: DNSQueryFailureCallback) {

        let dnsClient: DNSClient = DNSClient()
        dnsClient.queryNameserver(serverHost, serverPort: serverPort, forName: qname, recordType: recordType, success: { responseString in

            dnsClient.stop()
            // dnsClient = nil

            successCallback(responseString)

        }) { error in

            dnsClient.stop()
            //dnsClient = nil

            failureCallback(error)
        }
    }

    ///
    class func queryNameserver(serverHost: String, serverPort: UInt16, forName qname: String, recordType: String,
                               success successCallback: DNSQuerySuccessCallback, failure failureCallback: DNSQueryFailureCallback) {

        let recordTypeInt = UInt16(DNSServiceTypeStrToInt[recordType]!)

        DNSClient.queryNameserver(serverHost, serverPort: serverPort, forName: qname, recordType: recordTypeInt, success: successCallback, failure: failureCallback)
    }

    ///
    class func query(qname: String, recordType: UInt16, success successCallback: DNSQuerySuccessCallback, failure failureCallback: DNSQueryFailureCallback) {

        let dnsClient: DNSClient = DNSClient()
        dnsClient.query(qname, recordType: recordType, success: { responseString in

            dnsClient.stop()
            // dnsClient = nil

            successCallback(responseString)

        }) { error in

            dnsClient.stop()
            // dnsClient = nil

            failureCallback(error)
        }
    }

    ///
    class func query(qname: String, recordType: String, success successCallback: DNSQuerySuccessCallback, failure failureCallback: DNSQueryFailureCallback) {

        let recordTypeInt = UInt16(DNSServiceTypeStrToInt[recordType]!)

        DNSClient.query(qname, recordType: recordTypeInt, success: successCallback, failure: failureCallback)
    }

// MARK: query methods

    ///
    func queryNameserver(serverHost: String, serverPort: UInt16, forName qname: String, recordType: UInt16,
                         success successCallback: DNSQuerySuccessCallback, failure failureCallback: DNSQueryFailureCallback) {

        let data = buildQueryData(qname, recordType: recordType)

        let callbackKey = "\(qname)_\(recordType)"

        callbackSuccessMap[callbackKey] = successCallback
        callbackFailureMap[callbackKey] = failureCallback

        udpSocket.sendData(data, toHost: serverHost, port: serverPort, withTimeout: -1, tag: -1)
    }

    ///
    func queryNameserver(serverHost: String, serverPort: UInt16, forName qname: String, recordType: String,
                         success successCallback: DNSQuerySuccessCallback, failure failureCallback: DNSQueryFailureCallback) {

        let recordTypeInt = UInt16(DNSServiceTypeStrToInt[recordType]!)

        queryNameserver(serverHost, serverPort: serverPort, forName: qname, recordType: recordTypeInt, success: successCallback, failure: failureCallback)
    }

    ///
    func query(qname: String, recordType: UInt16, success successCallback: DNSQuerySuccessCallback, failure failureCallback: DNSQueryFailureCallback) {
        queryNameserver(dnsServer, serverPort: dnsPort, forName: qname, recordType: recordType, success: successCallback, failure: failureCallback)
    }

    ///
    func query(qname: String, recordType: String, success successCallback: DNSQuerySuccessCallback, failure failureCallback: DNSQueryFailureCallback) {
        queryNameserver(dnsServer, serverPort: dnsPort, forName: qname, recordType: recordType, success: successCallback, failure: failureCallback)
    }

// MARK: other

    ///
    func buildQueryData(qname: String, recordType: UInt16) -> NSData {
        // header

        var requestDNSHeader: DNSHeader = DNSHeader()
        requestDNSHeader.id = UInt16(arc4random_uniform(UInt32(UInt16.max)) + 1).bigEndian // random id
        requestDNSHeader.flags = CFSwapInt16HostToBig(256)
        requestDNSHeader.qdCount = CFSwapInt16HostToBig(1)
        requestDNSHeader.anCount = CFSwapInt16HostToBig(0)
        requestDNSHeader.nsCount = CFSwapInt16HostToBig(0)
        requestDNSHeader.arCount = CFSwapInt16HostToBig(0)

        let requestHeaderData = NSData(bytes: &requestDNSHeader, length: sizeof(DNSHeader))

        // qname

        let qname_data = parseQNameToNSData(qname)

        // question

        var requestDNSQuestion: DNSQuestion = DNSQuestion()
        //requestDNSQuestion.name = "alladin.at"
        requestDNSQuestion.dnsType = /*CFSwapInt16HostToBig(*/recordType.bigEndian/*)*/
        requestDNSQuestion.dnsClass = /*CFSwapInt16HostToBig(*/UInt16(kDNSServiceClass_IN).bigEndian/*)*/

        let request2BodyData = NSData(bytes: &requestDNSQuestion, length: sizeof(DNSQuestion))

        //

        let data: NSMutableData = NSMutableData()
        data.appendData(requestHeaderData)
        data.appendData(qname_data)
        data.appendData(request2BodyData)

        //println(data)
        logger.debug("\(data)")

        return data
    }

    ///
    @objc func udpSocket(sock: GCDAsyncUdpSocket, didConnectToAddress address: NSData) {
        //println("didConnectToAddress: \(address)")
        logger.debug("didConnectToAddress: \(address)")
    }

    ///
    @objc func udpSocket(sock: GCDAsyncUdpSocket, didNotConnect error: NSError?) {
        //println("didNotConnect: \(error)")
        logger.debug("didNotConnect: \(error)")
    }

    ///
    @objc func udpSocket(sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        //println("didSendDataWithTag: \(tag)")
        logger.debug("didSendDataWithTag: \(tag)")
    }

    ///
    @objc func udpSocket(sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: NSError?) {
        //println("didNotSendDataWithTag: \(error)")
        logger.debug("didNotSendDataWithTag: \(error)")
    }

    ///
    @objc func udpSocket(sock: GCDAsyncUdpSocket, didReceiveData data: NSData, fromAddress address: NSData, withFilterContext filterContext: AnyObject?) {

        dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) { // needed because otherwise println's would merge strangely, TODO: remove this later

            var dnsRecordClass: DNSRecordClass!

//            println("didReceiveData: \(data)")

            let subdata = data.subdataWithRange(NSRange(location: 0, length: sizeof(DNSHeader)))
//            println("subdata: \(subdata)")

            //var dnsHeaderPointer: UnsafeMutablePointer<DNSHeader> = UnsafeMutablePointer<DNSHeader>.alloc(sizeof(DNSHeader))
            var dnsHeader: DNSHeader = DNSHeader()

            /*data*/subdata.getBytes(&dnsHeader, length: sizeof(DNSHeader)) /*dnsHeaderPointer*/

            //var dnsHeader: DNSHeader = dnsHeaderPointer.move()

            dnsHeader.id = CFSwapInt16BigToHost(dnsHeader.id)
            dnsHeader.flags = CFSwapInt16BigToHost(dnsHeader.flags)
            dnsHeader.qdCount = CFSwapInt16BigToHost(dnsHeader.qdCount)
            dnsHeader.anCount = CFSwapInt16BigToHost(dnsHeader.anCount)
            dnsHeader.nsCount = CFSwapInt16BigToHost(dnsHeader.nsCount)
            dnsHeader.arCount = CFSwapInt16BigToHost(dnsHeader.arCount)

//            println(dnsHeader)

            // get rcode
            let rcode = UInt8(dnsHeader.flags & 0x000F)
            //print("!!!!!!!!!!!!!!!!!!! RCODE: \(rcode) !!!!!!!!!!!!!")

            ////

            let subdata2 = data.subdataWithRange(NSRange(location: sizeof(DNSHeader), length: data.length - sizeof(DNSHeader)))
//            println("subdata2: \(subdata2)")

            // reconstruct qname

            let qname = self.parseNameFromData(subdata2, data: data, nameOffset: 0)
//            println("qname \(qname)")

            //var (qname, array) = self.parseQnameDataToString(subdata2)
            //println("qname: \(qname), array: \(array)")

            /////

            var zeroByte = [UInt8](count: 1, repeatedValue: 0)
            let zeroByteData = NSData(bytes: &zeroByte, length: sizeof(UInt8))

            let d_new_range = subdata2.rangeOfData(zeroByteData, options: [], range: NSRange(location: 0, length: subdata2.length))

//            println("d_new_range: \(d_new_range)")

            let d: NSData = subdata2.subdataWithRange(NSRange(location: d_new_range.location + 1, length: subdata2.length - (d_new_range.location + 1)))

            //let d: NSData = NSData(bytes: &array, length: array.count)

//            println("d: \(d)")
            //println("d_new: \(d_new)")

            var dnsQuestion: DNSQuestion = DNSQuestion()

            d.getBytes(&dnsQuestion, length: sizeof(DNSQuestion))

            dnsQuestion.dnsType = CFSwapInt16BigToHost(dnsQuestion.dnsType)
            dnsQuestion.dnsClass = CFSwapInt16BigToHost(dnsQuestion.dnsClass)

            //println(dnsQuestion)
            logger.debug("\(dnsQuestion)")

            ///
            let callbackKey = "\(qname)_\(dnsQuestion.dnsType)"
            ///

            ////////

            if dnsHeader.anCount > 0 {
                //println("trying to get \(dnsHeader.anCount) rr (currently one first one...)")
                logger.debug("trying to get \(dnsHeader.anCount) rr (currently one first one...)")

                let dd = d.subdataWithRange(NSRange(location: sizeof(DNSQuestion), length: d.length - sizeof(DNSQuestion)))

//                println("dd: \(dd)")

                // 16 bit => name pointer?
                // 16 bit => service type
                // 16 bit => service class
                // 32 bit => ttl
                // 16 bit => data length
                // data-length * 8 bit => data

                let ddr = dd.subdataWithRange(NSRange(location: 0, length: sizeof(DNSResourceRecord)))

//                println("ddr: \(ddr)")

                var dnsResourceRecord: DNSResourceRecord = DNSResourceRecord()

                /*dd*/ddr.getBytes(&dnsResourceRecord, length: 2+2+2)

                dnsResourceRecord.namePointer = CFSwapInt16BigToHost(dnsResourceRecord.namePointer)
                dnsResourceRecord.dnsType = CFSwapInt16BigToHost(dnsResourceRecord.dnsType)
                dnsResourceRecord.dnsClass = CFSwapInt16BigToHost(dnsResourceRecord.dnsClass)

                var ttlBytes: UInt32 = 0
                ddr.getBytes(&ttlBytes, range: NSRange(location: 2+2+2, length: sizeof(UInt32)))

                dnsResourceRecord.ttl = CFSwapInt32BigToHost(ttlBytes)

                var dataLengthBytes: UInt16 = 0
                ddr.getBytes(&dataLengthBytes, range: NSRange(location: 2+2+2+sizeof(UInt32), length: sizeof(UInt16)))

                dnsResourceRecord.dataLength = CFSwapInt16BigToHost(dataLengthBytes)

                // TODO: ttl!! and dataLength showing wrong numbers!!
                // TODO: bug is because ttl is uint32, but why is this not working?
                // -> see struct alignment...do it the other way with getBytes(..., range)

                //println(dnsResourceRecord)
                logger.debug("\(dnsResourceRecord)")

                let rdata = dd.subdataWithRange(NSRange(location: 2+2+2+4+2, length: Int(dnsResourceRecord.dataLength)))

                ///

                let strType = DNSServiceTypeIntToStr[Int(dnsResourceRecord.dnsType)]
                //println("rr is of type \(strType)")
                logger.debug("rr is of type \(strType)")

                //

                var ipStr: String!
                var preferenceNum: UInt16!

                //

                switch Int(dnsResourceRecord.dnsType) {
                case kDNSServiceType_A: // ipv4
                    let i4 = UnsafeMutablePointer<in_addr>.alloc(sizeof(in_addr))

                    rdata.getBytes(i4, length: sizeof(in_addr))

                    var u = [Int8](count: Int(INET_ADDRSTRLEN), repeatedValue: 0)

                    inet_ntop(AF_INET, i4, &u, socklen_t(INET_ADDRSTRLEN))

                    //ipStr = NSString(bytes: &u, length: u.count, encoding: NSASCIIStringEncoding)!
                    //ipStr = String.fromCString(u)!
                    ipStr = String(UTF8String: u)

                case kDNSServiceType_AAAA: // ipv6
                    let i6 = UnsafeMutablePointer<in6_addr>.alloc(sizeof(in6_addr))

                    rdata.getBytes(i6, length: sizeof(in6_addr))

                    var u = [Int8](count: Int(INET6_ADDRSTRLEN), repeatedValue: 0)

                    inet_ntop(AF_INET6, i6, &u, socklen_t(INET6_ADDRSTRLEN))

                    //ipStr = NSString(bytes: &u, length: u.count, encoding: NSASCIIStringEncoding)!
                    ipStr = String(UTF8String: u)

                case kDNSServiceType_MX: // mx

                    //println("MX")
                    logger.debug("MX")

                    // get preference
                    var preference: UInt16 = 0
                    rdata.getBytes(&preference, range: NSRange(location: 0, length: sizeof(UInt16)))

                    preference = CFSwapInt16BigToHost(preference)

                    preferenceNum = preference

                    //println("preference: \(preference)")
                    logger.debug("preference: \(preference)")

                    // get exchange
                    let exchangeLength = Int(dnsResourceRecord.dataLength) - sizeof(UInt16)
                    //println(exchangeLength)
                    logger.debug("\(exchangeLength)")

                    let exchangeData = rdata.subdataWithRange(NSRange(location: sizeof(UInt16), length: rdata.length - sizeof(UInt16)))

                    let mxName = self.parseNameFromData(exchangeData, data: data, nameOffset: 0)
                    //println("MX name: \(mxName)")
                    logger.debug("MX name: \(mxName)")

                    ipStr = mxName

                case kDNSServiceType_CNAME:

                    //println("CNAME")
                    logger.debug("CNAME")
                    //println(rdata)
                    logger.debug("\(rdata)")

                    let str = self.parseNameFromData(rdata, data: data, nameOffset: 0)
                    //println("STR: \(str)")
                    logger.debug("STR: \(str)")

                    ipStr = str // TODO: other field than ipStr

                default:
                    //println("unknown result type")
                    logger.debug("unknown result type")

                    //ipStr = "UNKNOWN"
                }

                //println("GOT DNS REPLY WITH IP: \(ipStr)")
                logger.debug("GOT DNS REPLY WITH IP: \(ipStr)")

                //self.stop() // TODO: when to close socket?

                dnsRecordClass = DNSRecordClass(name: qname, qType: dnsResourceRecord.dnsType, qClass: dnsResourceRecord.dnsClass, ttl: dnsResourceRecord.ttl, rcode: rcode)
                dnsRecordClass.ipAddress = ipStr
                dnsRecordClass.mxPreference = preferenceNum

                //if let _ = ipStr {
                //    self.callbackSuccessMap[callbackKey]?(dnsRecordClass)
                //} else {
                //    self.callbackFailureMap[callbackKey]?(NSError(domain: "err", code: 1000, userInfo: nil))
                //}

                /////////////////////////////////////////////////////////

//                let dnsRecordA: DNSRecordA = DNSRecordA(
//                    dnsRecord: DNSRecord(
//                        name: "",
//                        qType: 1,
//                        qClass: 1,
//                        ttl: 12
//                    ),
//                    address: "",
//                    addr: in_addr(s_addr: 0)
//                )

            } else {
                //println("there are no rr")
                logger.debug("there are no rr")

                //self.stop() // TODO: when to close socket?

                dnsRecordClass = DNSRecordClass(name: qname, rcode: rcode)

                // TODO: check errors and then call failure callback
                //self.callbackFailureMap[callbackKey]?(NSError(domain: "err", code: 12, userInfo: nil))
            }

            // call callback
            self.callbackSuccessMap[callbackKey]?(dnsRecordClass)
        }
    }

    ///
    @objc func udpSocketDidClose(sock: GCDAsyncUdpSocket, withError error: NSError?) { // crashes if NSError is used without questionmark
        logger.debug("udpSocketDidClose: \(error)")
    }

    /////////////////////////////////

// MARK: Helper methods

    ///
    private func parseNameFromData(subData: NSData, data: NSData, nameOffset: UInt) -> String {
        //println("____--____")

        var name: String = ""

        var localOffset = Int(nameOffset)

        while localOffset < /*data*/subData.length {

            var firstByteOfBlock: UInt8 = 0

            /*data*/subData.getBytes(&firstByteOfBlock, range: NSRange(location: localOffset, length: sizeof(UInt8)))
            localOffset += sizeof(UInt8)

            //println("firstByteOfBlock: \(firstByteOfBlock)")

            if firstByteOfBlock == 0 {
                //println("str end, break")
                break
            }

            if firstByteOfBlock >= 192 {
                // this is a pointer
                //println("this is a pointer")

                // get pointer -> pointer is 14 bit, first 2 bits of this 2 byte value are 11 for pointer
                var pointer: UInt16 = 0
                /*data*/subData.getBytes(&pointer, range: NSRange(location: localOffset - sizeof(UInt8), length: sizeof(UInt16)))
                localOffset += sizeof(UInt8)

                pointer = CFSwapInt16BigToHost(pointer)

                let realPointer = pointer & 0x3FFF

                //println("got pointer: \(realPointer), name at the \(realPointer)'th bit")

                name += parseNameFromData(data, data: data, nameOffset: UInt(realPointer))

            } else {
                // this is a count for the next name part

                //println("this is a count: \(firstByteOfBlock)")

                let rangeData = subData.subdataWithRange(NSRange(location: localOffset, length: Int(firstByteOfBlock)))
                let partStr = NSString(data: rangeData, encoding: NSASCIIStringEncoding)!

                localOffset += Int(firstByteOfBlock)

                //println("partStr: \(partStr)")

                name += (partStr as String) + "."
            }
        }

        if name.hasSuffix(".") {
            name = name.substringToIndex(name.endIndex.predecessor())
        }

        return name
    }

    ///
    private func parseQNameToNSData(qname: String) -> NSData {
        let splitted_qname = qname.componentsSeparatedByString(".")//split(qname) { $0 == "." }

        print(splitted_qname)

        let qname_data = NSMutableData()

        for part in splitted_qname {
            var part_count: UInt8 = /*CFSwapInt8HostToBig(*/UInt8(part.characters.count)/*)*/

//            println("part: \(part), count: \(part_count)")

            // append count
            qname_data.appendBytes(&part_count, length: sizeof(UInt8))

            // append string
            qname_data.appendData(part.dataUsingEncoding(NSASCIIStringEncoding)!) // !
        }

        var n: UInt8 = 0
        qname_data.appendBytes(&n, length: sizeof(UInt8))

//        println("qname_data: \(qname_data)")

        return qname_data
    }
}
