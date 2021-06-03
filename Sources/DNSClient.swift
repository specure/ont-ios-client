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
#if swift(>=3.2)
    import Darwin
    import dnssd
#else
    import RMBTClientPrivate
#endif

///
class DNSClient: NSObject, GCDAsyncUdpSocketDelegate {

    typealias DNSQuerySuccessCallback = (DNSRecordClass) -> ()
    typealias DNSQueryFailureCallback = (NSError?) -> ()

    //

    ///
    private let delegateQueue = DispatchQueue(label: "com.specure.dns.client", attributes: DispatchQueue.Attributes.concurrent)

    ///
    private var udpSocket: GCDAsyncUdpSocket!

    //

    private var callbackSuccessMap = [String: DNSQuerySuccessCallback]()
    private var callbackFailureMap = [String: DNSQueryFailureCallback]()

    //
    private var isFinished = false
    ///
    private let dnsServer: String

    ///
    private let dnsPort: UInt16

    ///
    override convenience init() {
        let dnsIpDict = GetDNSIP.getdnsIPandPort()

        let host: String = dnsIpDict!["host"] as! String
        let port = (dnsIpDict?["port"] as! NSNumber).uint16Value

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
        udpSocket.setupSocket()
        do {
            // bind to port
            Log.logger.debug("- binding to port 0")

            try udpSocket.bind(toPort: 0)

            Log.logger.debug("- begin receiving")

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
    class func queryNameserver(_ serverHost: String, serverPort: UInt16, forName qname: String, recordTypeInt: UInt16,
                               success successCallback: @escaping DNSQuerySuccessCallback, failure failureCallback: @escaping DNSQueryFailureCallback) -> DNSClient {

        let dnsClient: DNSClient = DNSClient()
        dnsClient.queryNameserver(serverHost, serverPort: serverPort, forName: qname, recordTypeInt: recordTypeInt, success: { [weak dnsClient] responseString in

            dnsClient?.stop()
            // dnsClient = nil

            successCallback(responseString)

        }) { [weak dnsClient] error in

            dnsClient?.stop()
            //dnsClient = nil

            failureCallback(error)
        }
        return dnsClient
    }

    ///
    class func queryNameserver(_ serverHost: String, serverPort: UInt16, forName qname: String, recordType: String,
                               success successCallback: @escaping DNSQuerySuccessCallback, failure failureCallback: @escaping DNSQueryFailureCallback) -> DNSClient {

        let recordTypeInt = UInt16(DNSServiceTypeStrToInt[recordType]!)

        return DNSClient.queryNameserver(serverHost, serverPort: serverPort, forName: qname, recordTypeInt: recordTypeInt, success: successCallback, failure: failureCallback)
    }

    ///
    class func query(_ qname: String, recordType: UInt16, success successCallback: @escaping DNSQuerySuccessCallback, failure failureCallback: @escaping DNSQueryFailureCallback) -> DNSClient {

        let dnsClient: DNSClient = DNSClient()
        dnsClient.query(qname, recordType: recordType, success: { [weak dnsClient] responseString in

            dnsClient?.stop()
            // dnsClient = nil

            successCallback(responseString)

        }) { [weak dnsClient] error in

            dnsClient?.stop()
            // dnsClient = nil

            failureCallback(error)
        }
        
        return dnsClient
    }

    ///
    class func query(_ qname: String, recordType: String, success successCallback: @escaping DNSQuerySuccessCallback, failure failureCallback: @escaping DNSQueryFailureCallback) -> DNSClient {

        let recordTypeInt = UInt16(DNSServiceTypeStrToInt[recordType]!)

        return DNSClient.query(qname, recordType: recordTypeInt, success: successCallback, failure: failureCallback)
    }

// MARK: query methods

    ///
    func queryNameserver(_ serverHost: String, serverPort: UInt16, forName qname: String, recordTypeInt: UInt16,
                         success successCallback: @escaping DNSQuerySuccessCallback, failure failureCallback: @escaping DNSQueryFailureCallback) {

        let data = buildQueryData(qname, recordType: recordTypeInt)

        let callbackKey = "\(qname)_\(recordTypeInt)"

        callbackSuccessMap[callbackKey] = successCallback
        callbackFailureMap[callbackKey] = failureCallback

        udpSocket.send(data, toHost: serverHost, port: serverPort, withTimeout: -1, tag: -1)
    }

    ///
    func queryNameserver(_ serverHost: String, serverPort: UInt16, forName qname: String, recordType: String,
                         success successCallback: @escaping DNSQuerySuccessCallback, failure failureCallback: @escaping DNSQueryFailureCallback) {

        let recordTypeInt = UInt16(DNSServiceTypeStrToInt[recordType]!)

        queryNameserver(serverHost, serverPort: serverPort, forName: qname, recordTypeInt: recordTypeInt, success: successCallback, failure: failureCallback)
    }

    ///
    func query(_ qname: String, recordType: UInt16, success successCallback: @escaping DNSQuerySuccessCallback, failure failureCallback: @escaping DNSQueryFailureCallback) {
        queryNameserver(dnsServer, serverPort: dnsPort, forName: qname, recordTypeInt: recordType, success: successCallback, failure: failureCallback)
    }

    ///
    func query(_ qname: String, recordType: String, success successCallback: @escaping DNSQuerySuccessCallback, failure failureCallback: @escaping DNSQueryFailureCallback) {
        queryNameserver(dnsServer, serverPort: dnsPort, forName: qname, recordType: recordType, success: successCallback, failure: failureCallback)
    }

// MARK: other

    ///
    func buildQueryData(_ qname: String, recordType: UInt16) -> Data {
        // header

        var requestDNSHeader: DNSHeader = DNSHeader()
        requestDNSHeader.id = UInt16(arc4random_uniform(UInt32(UInt16.max)) + 1).bigEndian // random id
        requestDNSHeader.flags = CFSwapInt16HostToBig(256)
        requestDNSHeader.qdCount = CFSwapInt16HostToBig(1)
        requestDNSHeader.anCount = CFSwapInt16HostToBig(0)
        requestDNSHeader.nsCount = CFSwapInt16HostToBig(0)
        requestDNSHeader.arCount = CFSwapInt16HostToBig(0)

        let requestHeaderData = Data(buffer: UnsafeBufferPointer(start: &requestDNSHeader, count: 1)) // Data(bytes: UnsafePointer<UInt8>(&requestDNSHeader), count: sizeof(DNSHeader))

        // qname

        let qname_data = parseQNameToData(qname)

        // question

        var requestDNSQuestion: DNSQuestion = DNSQuestion()
        //requestDNSQuestion.name = "alladin.at"
        requestDNSQuestion.dnsType = /*CFSwapInt16HostToBig(*/recordType.bigEndian/*)*/
        requestDNSQuestion.dnsClass = /*CFSwapInt16HostToBig(*/UInt16(kDNSServiceClass_IN).bigEndian/*)*/

        let request2BodyData =  Data(buffer: UnsafeBufferPointer(start: &requestDNSQuestion, count: 1)) // Data(bytes: UnsafePointer<UInt8>(&requestDNSQuestion), count: sizeof(DNSQuestion))

        //

//        let data: NSMutableData = NSMutableData()
//        data.append(requestHeaderData)
//        data.append(qname_data)
//        data.append(request2BodyData)
        
        var data = Data()
            data.append(requestHeaderData)
            data.append(qname_data)
            data.append(request2BodyData)

        Log.logger.debug("\(data as NSData)")

        return data as Data
    }

    ///
    @objc func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        //println("didConnectToAddress: \(address)")
        Log.logger.debug("didConnectToAddress: \(address)")
    }

    ///
    @objc func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        //println("didNotConnect: \(error)")
        Log.logger.debug("didNotConnect: \(String(describing: error))")
    }

    ///
    @objc func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        //println("didSendDataWithTag: \(tag)")
        Log.logger.debug("didSendDataWithTag: \(tag)")
    }

    ///
    func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        //println("didNotSendDataWithTag: \(error)")
        Log.logger.debug("didNotSendDataWithTag: \(String(describing: error))")
    }

    ///
    func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
//        https://tools.ietf.org/html/rfc1035
        DispatchQueue.global(qos: .default).async{ // needed because otherwise println's would merge strangely, TODO: remove this later
            var currentData = data
            Log.logger.debug("address: \(address.base64EncodedString())")

        //// ??????
            let range = NSRange(location: 0, length: MemoryLayout<DNSHeader>.size)
            // let newRange: Range<Int> = 0..<MemoryLayout<DNSHeader>.size

            if currentData.count < range.length {
                return
            }
            let headerData = (currentData as NSData).subdata(with: range)

            //Log.logger.debug("\(subdata.base64EncodedString())")
//////////////
            var dnsHeader: DNSHeader = DNSHeader()

            /*data*/(headerData as NSData).getBytes(&dnsHeader, length: MemoryLayout<DNSHeader>.size) /*dnsHeaderPointer*/

            dnsHeader.id = CFSwapInt16BigToHost(dnsHeader.id)
            dnsHeader.flags = CFSwapInt16BigToHost(dnsHeader.flags)
            dnsHeader.qdCount = CFSwapInt16BigToHost(dnsHeader.qdCount)
            dnsHeader.anCount = CFSwapInt16BigToHost(dnsHeader.anCount)
            dnsHeader.nsCount = CFSwapInt16BigToHost(dnsHeader.nsCount)
            dnsHeader.arCount = CFSwapInt16BigToHost(dnsHeader.arCount)

            print(dnsHeader)
        
            /*
            let qr = (dnsHeader.flags >> 15)
            let opcode = (dnsHeader.flags << 1) & 0xF000
            let aa = (dnsHeader.flags << 5) >> 15
            let tc = (dnsHeader.flags << 6) >> 15
            let rd = (dnsHeader.flags << 7) >> 15
            let ra = (dnsHeader.flags << 8) >> 15
            let z = (dnsHeader.flags << 9) >> 15
             */
            
            let rcode = (dnsHeader.flags & 0x000F)
            ////
            currentData = currentData.subdata(in: headerData.count..<currentData.count)

            Log.logger.debug("\(currentData.base64EncodedString())")

            var dnsQuestion: DNSQuestion = DNSQuestion()
            var dnsQuestionName = ""
            
            if dnsHeader.qdCount > 0 {
                var offset = 0
                let qnameExtracts = currentData.extractStringByOctets()
                let qname = qnameExtracts.string ?? ""
                
                offset = qnameExtracts.offset
                var qtype: UInt16 = 0
                (currentData as NSData).getBytes(&qtype, range: NSRange(location: offset, length:  MemoryLayout<UInt16>.size))
                offset += MemoryLayout<UInt16>.size
                
                var qclass: UInt16 = 0
                (currentData as NSData).getBytes(&qclass, range: NSRange(location: offset, length:  MemoryLayout<UInt16>.size))
                offset += MemoryLayout<UInt16>.size
                
                Log.logger.debug("qname \(qname)")
                Log.logger.debug("qtype \(qtype)")
                Log.logger.debug("qclass \(qclass)")
                
                dnsQuestion.dnsType = CFSwapInt16BigToHost(qtype)
                dnsQuestion.dnsClass = CFSwapInt16BigToHost(qclass)
                dnsQuestionName = qname
                
                currentData = currentData.subdata(in: offset..<currentData.count)
            }

            Log.logger.debug("\(dnsQuestion)")

//            if dnsQuestionName == "wikipedia.org" || dnsQuestionName == "slovenskenovice.si" || dnsQuestionName == "apple.com" {
//                print("")
//            }
            ///
            let callbackKey = "\(dnsQuestionName)_\(dnsQuestion.dnsType)"
            ///
            var dnsRecordClass: DNSRecordClass!
            ////////

            if dnsHeader.anCount > 0 {
                let nameExtract = currentData.extractFirstDNSResourceName(separator: 192)
                var offset = nameExtract.offset
                var isSkipName = false
                
                if nameExtract.string != nil,
                    nameExtract.offset > 0 {
                    isSkipName = true
                }
                if nameExtract.string == nil,
                    currentData[0] == 192 {
                    currentData = currentData[1..<currentData.count]
                }
                
                //println("trying to get \(dnsHeader.anCount) rr (currently one first one...)")
                Log.logger.debug("trying to get \(dnsHeader.anCount) rr (currently one first one...)")

                // 16 bit => name pointer?
                // 16 bit => service type
                // 16 bit => service class
                // 32 bit => ttl
                // 16 bit => data length
                // data-length * 8 bit => data

                var length = MemoryLayout<DNSResourceRecord>.size
                if length > currentData.count {
                    length = currentData.count
                }
                
                //let ddr = dd.subdata(in: 0..<MemoryLayout<DNSResourceRecord>.size)

                Log.logger.debug("ddr: \(currentData.base64EncodedString())")

                var dnsResourceRecord = DNSResourceRecord()

                var size = 0
                
                var namePointer = dnsResourceRecord.namePointer
                var dnsType = dnsResourceRecord.dnsType
                var dnsClass = dnsResourceRecord.dnsClass
                var ttlBytes = dnsResourceRecord.ttl
                var dataLength = dnsResourceRecord.dataLength
                
                if !isSkipName {
                    size = MemoryLayout<UInt8>.size
                    (currentData as NSData).getBytes(&namePointer, range: NSRange(location: offset, length: size))
                    offset += size
                }
                
                size = MemoryLayout<UInt16>.size
                (currentData as NSData).getBytes(&dnsType, range: NSRange(location: offset, length: size))
                offset += size
                
                size = MemoryLayout<UInt16>.size
                (currentData as NSData).getBytes(&dnsClass, range: NSRange(location: offset, length: size))
                offset += size
                
                size = MemoryLayout<UInt32>.size
                (currentData as NSData).getBytes(&ttlBytes, range: NSRange(location: offset, length: size))
                offset += size
                
                size = MemoryLayout<UInt16>.size
                (currentData as NSData).getBytes(&dataLength, range: NSRange(location: offset, length: size))
                offset += size

                dnsResourceRecord.namePointer = namePointer
                dnsResourceRecord.dnsType = CFSwapInt16BigToHost(dnsType)
                dnsResourceRecord.dnsClass = CFSwapInt16BigToHost(dnsClass)
                dnsResourceRecord.ttl = CFSwapInt32BigToHost(ttlBytes)
                dnsResourceRecord.dataLength = CFSwapInt16BigToHost(dataLength)

//                if !isSkipName {
//                    print(nameExtract.string)
//                } else {
//                    let someName = (Data(data[Int(dnsResourceRecord.namePointer)..<data.count])).extractStringByOctets()
//                    print(someName.string)
//                }
                
                // TODO: ttl!! and dataLength showing wrong numbers!!
                // TODO: bug is because ttl is uint32, but why is this not working?
                // -> see struct alignment...do it the other way with getBytes(..., range)

                //println(dnsResourceRecord)
                Log.logger.debug("\(dnsResourceRecord)")

                // let rdata = dd.subdata(with: NSRange(location: 2+2+2+4+2, length: Int(dnsResourceRecord.dataLength)))
                //let rdata = dd.subdata(in: 2+2+2+4+2..<2+2+2+4+2+Int(dnsResourceRecord.dataLength))
                
                let rdata = (currentData as NSData).subdata(with: NSRange(location: offset, length: Int(dnsResourceRecord.dataLength)))

                ///

                let strType = DNSServiceTypeIntToStr[Int(dnsResourceRecord.dnsType)]

                Log.logger.debug("rr is of type \(String(describing: strType))")

                //
                var ipStr: String!
                var preferenceNum: UInt16!

                //

                switch Int(dnsResourceRecord.dnsType) {
                case kDNSServiceType_A: // ipv4
                    let i4 = UnsafeMutablePointer<in_addr>.allocate(capacity: MemoryLayout<in_addr>.size)

                    (rdata as NSData).getBytes(i4, length: MemoryLayout<in_addr>.size)

                    var u = [Int8](repeating: 0, count: Int(INET_ADDRSTRLEN))

                    inet_ntop(AF_INET, i4, &u, socklen_t(INET_ADDRSTRLEN))

                    //ipStr = NSString(bytes: &u, length: u.count, encoding: NSASCIIStringEncoding)!
                    //ipStr = String.fromCString(u)!
                    ipStr = String(validatingUTF8: u)
                    i4.deallocate()
                case kDNSServiceType_AAAA: // ipv6
                    let i6 = UnsafeMutablePointer<in6_addr>.allocate(capacity: MemoryLayout<in6_addr>.size)

                    (rdata as NSData).getBytes(i6, length: MemoryLayout<in6_addr>.size)

                    var u = [Int8](repeating: 0, count: Int(INET6_ADDRSTRLEN))

                    inet_ntop(AF_INET6, i6, &u, socklen_t(INET6_ADDRSTRLEN))

                    //ipStr = NSString(bytes: &u, length: u.count, encoding: NSASCIIStringEncoding)!
                    ipStr = String(validatingUTF8: u)
                    i6.deallocate()
                case kDNSServiceType_MX: // mx

                    //println("MX")
                    Log.logger.debug("MX")

                    // get preference
                    var preference: UInt16 = 0
                    (rdata as NSData).getBytes(&preference, range: NSRange(location: 0, length: MemoryLayout<UInt16>.size))

                    preference = CFSwapInt16BigToHost(preference)

                    preferenceNum = preference

                    //println("preference: \(preference)")
                    Log.logger.debug("preference: \(preference)")

                    // get exchange
                    let exchangeLength = Int(dnsResourceRecord.dataLength) - MemoryLayout<UInt16>.size
                    //println(exchangeLength)
                    Log.logger.debug("\(exchangeLength)")

//                    let exchangeData = rdata.subdata(with: NSRange(location: MemoryLayout<UInt16>.size, length: rdata.count - MemoryLayout<UInt16>.size))
                    
                    let exchangeData = rdata.subdata(in: MemoryLayout<UInt16>.size..<rdata.count)

                    let mxName = self.parseNameFromData(exchangeData, data: data, nameOffset: 0)
                    //println("MX name: \(mxName)")
                    Log.logger.debug("MX name: \(mxName)")

                    ipStr = mxName

                case kDNSServiceType_CNAME:

                    //println("CNAME")
                    Log.logger.debug("CNAME")
                    //println(rdata)
                    Log.logger.debug("\(rdata)")

                    let str = self.parseNameFromData(rdata, data: data, nameOffset: 0)
                    //println("STR: \(str)")
                    Log.logger.debug("STR: \(str)")

                    ipStr = str // TODO: other field than ipStr

                default:
                    //println("unknown result type")
                    Log.logger.debug("unknown result type")

                    //ipStr = "UNKNOWN"
                }
                Log.logger.debug("GOT DNS REPLY WITH IP: \(String(describing: ipStr))")

                //self.stop() // TODO: when to close socket?

                dnsRecordClass = DNSRecordClass(name: dnsQuestionName, qType: dnsResourceRecord.dnsType, qClass: dnsResourceRecord.dnsClass, ttl: dnsResourceRecord.ttl, rcode: UInt8(rcode))
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
                Log.logger.debug("there are no rr")

                //self.stop() // TODO: when to close socket?

                dnsRecordClass = DNSRecordClass(name: dnsQuestionName, rcode: UInt8(rcode))

                // TODO: check errors and then call failure callback
                //self.callbackFailureMap[callbackKey]?(NSError(domain: "err", code: 12, userInfo: nil))
            }

            // call callback
            self.callbackSuccessMap[callbackKey]?(dnsRecordClass)
        }
    }

    ///
    func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) { // crashes if NSError is used without questionmark
        Log.logger.debug("udpSocketDidClose: \(String(describing: error))")
//        if isFinished == false {
//            for callback in callbackFailureMap {
//                callback.value(error as? NSError)
//            }
//        }
    }
    

    /////////////////////////////////

// MARK: Helper methods

    ///
    private func parseNameFromData(_ subData: Data, data: Data, nameOffset: UInt) -> String {
        //println("____--____")

        var name: String = ""

        var localOffset = Int(nameOffset)

        while localOffset < /*data*/subData.count {

            var firstByteOfBlock: UInt8 = 0

            /*data*/(subData as NSData).getBytes(&firstByteOfBlock, range: NSRange(location: localOffset, length: MemoryLayout<UInt8>.size))
            localOffset += MemoryLayout<UInt8>.size

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
                /*data*/(subData as NSData).getBytes(&pointer, range: NSRange(location: localOffset - MemoryLayout<UInt8>.size, length: MemoryLayout<UInt16>.size))
                localOffset += MemoryLayout<UInt8>.size

                pointer = CFSwapInt16BigToHost(pointer)

                let realPointer = pointer & 0x3FFF

                //println("got pointer: \(realPointer), name at the \(realPointer)'th bit")

                name += parseNameFromData(data, data: data, nameOffset: UInt(realPointer))

            } else {
                // this is a count for the next name part

                //println("this is a count: \(firstByteOfBlock)")

                let rangeData = subData.subdata(in: localOffset..<localOffset+Int(firstByteOfBlock) /*NSRange(location: localOffset, length: Int(firstByteOfBlock))*/)
                let partStr = NSString(data: rangeData, encoding: String.Encoding.ascii.rawValue)!

                localOffset += Int(firstByteOfBlock)

                //println("partStr: \(partStr)")

                name += (partStr as String) + "."
            }
        }

        if name.hasSuffix(".") {
            let index = name.index(before: name.endIndex)
            name = String(name[..<index])
        }

        return name
    }

    ///
    private func parseQNameToData(_ qname: String) -> Data {
        let splitted_qname = qname.components(separatedBy: ".")//split(qname) { $0 == "." }

        print(splitted_qname)

        let qname_data = NSMutableData()

        for part in splitted_qname {
            var part_count: UInt8 = /*CFSwapInt8HostToBig(*/UInt8(part.count)/*)*/

//            println("part: \(part), count: \(part_count)")

            // append count
            qname_data.append(&part_count, length: MemoryLayout<UInt8>.size)

            // append string
            qname_data.append(part.data(using: String.Encoding.ascii)!) // !
        }

        var n: UInt8 = 0
        qname_data.append(&n, length: MemoryLayout<UInt8>.size)

//        println("qname_data: \(qname_data)")

        return qname_data as Data
    }
}
