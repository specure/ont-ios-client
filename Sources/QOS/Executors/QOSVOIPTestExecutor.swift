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
typealias VOIPTestExecutor = QOSVOIPTestExecutor<QOSVOIPTest>

///
class QOSVOIPTestExecutor<T: QOSVOIPTest>: QOSTestExecutorClass<T>, UDPStreamSenderDelegate {

    private let RESULT_VOIP_PREFIX          = "voip_result"
    private let RESULT_VOIP_PREFIX_INCOMING = "_in_"
    private let RESULT_VOIP_PREFIX_OUTGOING = "_out_"

    ///

    private let RESULT_VOIP_PAYLOAD             = "voip_objective_payload"
    private let RESULT_VOIP_IN_PORT             = "voip_objective_in_port"
    private let RESULT_VOIP_OUT_PORT            = "voip_objective_out_port"
    private let RESULT_VOIP_CALL_DURATION       = "voip_objective_call_duration"
    private let RESULT_VOIP_BITS_PER_SAMPLE     = "voip_objective_bits_per_sample"
    private let RESULT_VOIP_SAMPLE_RATE         = "voip_objective_sample_rate"
    private let RESULT_VOIP_DELAY               = "voip_objective_delay"
    private let RESULT_VOIP_STATUS              = "voip_result_status"
    private let RESULT_VOIP_VOIP_PREFIX         = "voip_result"
    private let RESULT_VOIP_INCOMING_PREFIX     = "_in_"
    private let RESULT_VOIP_OUTGOING_PREFIX     = "_out_"
    private let RESULT_VOIP_SHORT_SEQUENTIAL    = "short_seq"
    private let RESULT_VOIP_LONG_SEQUENTIAL     = "long_seq"
    private let RESULT_VOIP_MAX_JITTER          = "max_jitter"
    private let RESULT_VOIP_MEAN_JITTER         = "mean_jitter"
    private let RESULT_VOIP_MAX_DELTA           = "max_delta"
    private let RESULT_VOIP_SKEW                = "skew"
    private let RESULT_VOIP_NUM_PACKETS         = "num_packets"
    private let RESULT_VOIP_SEQUENCE_ERRORS     = "sequence_error"
    private let RESULT_VOIP_TIMEOUT             = "voip_objective_timeout"
    //
    //ONT
    private let RESULT_VOIP_IN_SHORT_SEQ        = "voip_result_in_short_seq"
    private let RESULT_VOIP_IN_NUM_PACKETS        = "voip_result_in_num_packets"
    private let RESULT_VOIP_IN_MAX_JITTER        = "voip_result_in_max_jitter"
    private let RESULT_VOIP_OUT_SKEW            = "voip_result_out_skew"
    

    //

    private let TAG_TASK_VOIPTEST = 4001
    private let TAG_TASK_VOIPRESULT = 4002

    //

    ///
    private var udpStreamSender: UDPStreamSender!

    ///
    private var initialSequenceNumber: UInt16!

    ///
    private var ssrc: UInt32!

    ///
    private var initialRTPPacket: RTPPacket!

    ///
    private var rtpControlDataList: [UInt16: RTPControlData] = [:]

    ///
    private var payloadSize: Int!

    ///
    private var payloadTimestamp: UInt32!
    
    private let TAG_TASK_VOIPTEST_cdl = CountDownLatch()
    private let TAG_TASK_VOIPRESULT_cdl = CountDownLatch()
    
    private let uniqueQueue = DispatchQueue(label: "Change rtpControlDataList")

    private var numPackets: UInt16 = 0
    ///
//    private var cdl: CountDownLatch! {
//        didSet {
//            print("New cdl")
//        }
//    }

    //

    ///
    override init(controlConnection: QOSControlConnection?, delegateQueue: DispatchQueue, testObject: T, speedtestStartTime: UInt64) {
        super.init(controlConnection: controlConnection, delegateQueue: delegateQueue, testObject: testObject, speedtestStartTime: speedtestStartTime)
    }

    ///
    override func startTest() {
        super.startTest()

        testResult.set(RESULT_VOIP_DELAY,           number: testObject.delay)
        testResult.set(RESULT_VOIP_BITS_PER_SAMPLE, number: testObject.bitsPerSample)
        testResult.set(RESULT_VOIP_CALL_DURATION,   number: testObject.callDuration)
        testResult.set(RESULT_VOIP_OUT_PORT,        number: testObject.portOut)
        testResult.set(RESULT_VOIP_IN_PORT,         number: testObject.portIn)
        testResult.set(RESULT_VOIP_SAMPLE_RATE,     number: testObject.sampleRate)
        testResult.set(RESULT_VOIP_PAYLOAD,         number: testObject.payloadType)
        testResult.set(RESULT_VOIP_STATUS,          value: "OK" as AnyObject?) // !
        testResult.set(RESULT_VOIP_TIMEOUT,         number: testObject.timeout)

        initialSequenceNumber = 0//UInt16(arc4random_uniform(10000) + 1)
    }

    ///
    override func endTest() {
        super.endTest()

        udpStreamSender?.stop()
    }

    ///
    override func executeTest() {
        qosLog.debug("EXECUTING VOIP TEST")

        // announce voip test
        var voipCommand = "VOIPTEST \(testObject.portOut!) \(testObject.portIn!) \(testObject.sampleRate) \(testObject.bitsPerSample) "
        voipCommand += "\(testObject.delay / NSEC_PER_MSEC) \(testObject.callDuration / NSEC_PER_MSEC) "
        voipCommand += "\(initialSequenceNumber!) \(testObject.payloadType)"

        sendTaskCommand(voipCommand, withTimeout: timeoutInSec, tag: TAG_TASK_VOIPTEST)

        cdlTimeout(for: TAG_TASK_VOIPTEST_cdl, 1000, forTag: "TAG_TASK_VOIPTEST")
    }

    ///
    override func testDidSucceed() {
        super.testDidSucceed()
    }

    ///
    override func testDidTimeout() {
        testResult.set(RESULT_VOIP_STATUS, value: "TIMEOUT" as AnyObject?)

        udpStreamSender?.stop()

        super.testDidTimeout()
    }

    ///
    override func testDidFail() {
        testResult.set(RESULT_VOIP_STATUS, value: "ERROR" as AnyObject?)

        udpStreamSender?.stop()

        super.testDidFail()
    }

// MARK: Other methods

    func cdlTimeout(for cdl: CountDownLatch, _ timeoutMs: UInt64, forTag: String) {
        let noTimeout = cdl.await(timeoutMs * NSEC_PER_MSEC)
        if !noTimeout {
            qosLog.debug("CDL TIMEOUT: \(forTag)")
            testDidTimeout()
        }
    }

// MARK: QOSTestExecutorProtocol methods

    ///
    override func needsCustomTimeoutHandling() -> Bool {
        return true
    }

// MARK: test methods

    ///
    private func startOutgoingTest() {
        if udpStreamSender != nil {
            return
        }
        let dDelay          = Double(testObject.delay / NSEC_PER_MSEC)
        let dSampleRate     = Double(testObject.sampleRate)
        let dBitsPerSample  = Double(testObject.bitsPerSample)
        let dCallDuration   = Double(testObject.callDuration / NSEC_PER_MSEC)
        let numPackets      = UInt16(dCallDuration / dDelay)
        self.numPackets = numPackets

        qosLog.debug("dDelay: \(dDelay)")
        qosLog.debug("dSampleRate: \(dSampleRate)")
        qosLog.debug("dBitsPerSample: \(dBitsPerSample)")
        qosLog.debug("dCallDuration: \(dCallDuration)")
        qosLog.debug("numPackets: \(numPackets)")

        //

        payloadSize         = Int(dSampleRate / (1000 / dDelay) * (dBitsPerSample / 8))
        payloadTimestamp    = UInt32(dSampleRate / (1000 / dDelay))

        qosLog.debug("payloadSize: \(payloadSize ?? 0)")
        qosLog.debug("payloadTimestamp: \(payloadTimestamp ?? 0)")

        //
        
        initialRTPPacket = RTPPacket()

        initialRTPPacket.header.payloadType = testObject.payloadType
        initialRTPPacket.header.ssrc = ssrc
        initialRTPPacket.header.sequenceNumber = initialSequenceNumber!

        //

        let settings: UDPStreamSenderSettings = UDPStreamSenderSettings(
            host: testObject.serverAddress,
            port: testObject.portOut!,
            delegateQueue: delegateQueue,
            sendResponse: true,
            maxPackets: numPackets,
            timeout: testObject.timeout,
            delay: testObject.delay,
            writeOnly: false,
            portIn: testObject.portIn
        )

        NSLog("=================numPackets=======\(numPackets)")
        udpStreamSender = UDPStreamSender(settings: settings)
        udpStreamSender.delegate = self

        // start timeout timer
//        startTimer()

        qosLog.debug("before send udpStreamSender")

        let ticksBeforeSend = UInt64.getCurrentTimeTicks()

        let boolOk = udpStreamSender.send()

        qosLog.debug("after send udpStreamSender (-> \(boolOk)) (took \(Double(UInt64.getTimeDifferenceInNanoSeconds(ticksBeforeSend)) / Double(NSEC_PER_MSEC))ms)")

        udpStreamSender.stop()

        // stop timeout timer
//        stopTimer()

        // timeout if sender ran into timeout
        //Doesn't need because we waiting timeout
//        if !boolOk {
//            testDidTimeout()
//            return
//        }

        // request results
        // wait short time (last udp packet could reach destination after this request resulting in strange server behaviour)
        
//        usleep(100000) /* 100 * 1000 */

        controlConnection?.sendTaskCommand("GET VOIPRESULT \(ssrc!)", withTimeout: timeoutInSec, forTaskId: testObject.qosTestId, tag: TAG_TASK_VOIPRESULT)

        
        var timeout = Int64(UInt64(self.timeoutInSec).toNanoTime()) - Int64(UInt64.getTimeDifferenceInNanoSeconds(testStartTimeTicks))
        if timeout < 0 {
            timeout = 0
        }
        
        cdlTimeout(for: TAG_TASK_VOIPRESULT_cdl, UInt64(timeout) / NSEC_PER_USEC, forTag: "TAG_TASK_VOIPRESULT")    
    }

    ///
    private func finishOutgoingTest() {
        qosLog.debug("FINISH OUTGOING VOIP TEST")

        let prefix = RESULT_VOIP_PREFIX + RESULT_VOIP_PREFIX_INCOMING

        let _start = UInt64.getCurrentTimeTicks()
        qosLog.debug("_calculateQOS start")

        // calculate QOS
        if let rtpResult = calculateQOS() {

            qosLog.debug("_calculateQOS took \(UInt64.getTimeDifferenceInNanoSeconds(_start) / NSEC_PER_MSEC) ms")

            qosLog.debug("rtpResult: \(rtpResult)")

            testResult.set(prefix + RESULT_VOIP_MAX_JITTER,         number: rtpResult.maxJitter)
            testResult.set(prefix + RESULT_VOIP_MEAN_JITTER,        number: rtpResult.meanJitter)
            testResult.set(prefix + RESULT_VOIP_MAX_DELTA,          number: rtpResult.maxDelta)
            testResult.set(prefix + RESULT_VOIP_SKEW,               number: rtpResult.skew)
            testResult.set(prefix + RESULT_VOIP_NUM_PACKETS,        number: rtpResult.receivedPackets)
            testResult.set(prefix + RESULT_VOIP_SEQUENCE_ERRORS,    number: rtpResult.outOfOrder)
            testResult.set(prefix + RESULT_VOIP_SHORT_SEQUENTIAL,   number: rtpResult.minSequential)
            testResult.set(prefix + RESULT_VOIP_LONG_SEQUENTIAL,    number: rtpResult.maxSequential)

        } else {

            testResult.set(prefix + RESULT_VOIP_MAX_JITTER,         value: nil)
            testResult.set(prefix + RESULT_VOIP_MEAN_JITTER,        value: nil)
            testResult.set(prefix + RESULT_VOIP_MAX_DELTA,          value: nil)
            testResult.set(prefix + RESULT_VOIP_SKEW,               value: nil)
            testResult.set(prefix + RESULT_VOIP_NUM_PACKETS,        number: 0)
            testResult.set(prefix + RESULT_VOIP_SEQUENCE_ERRORS,    value: nil)
            testResult.set(prefix + RESULT_VOIP_SHORT_SEQUENTIAL,   value: nil)
            testResult.set(prefix + RESULT_VOIP_LONG_SEQUENTIAL,    value: nil)
        }

        testDidSucceed()
    }

// MARK: calculate qos

    ///
    private func calculateQOS() -> RTPResult? {

        if rtpControlDataList.count <= 0 {
            return nil
        }

        //

        var jitterMap: [UInt16: Double] = [:]

        //var sequenceNumberArray: [UInt16] = [UInt16](rtpControlDataList.keys) // TODO: fatal error? TODO! also occured on 2016-06-07 14:09, again on 2016-07-27 17:34, again on 2016-08-11 15:19, again on 2016-08-17 17:20

        // since try/catch didn't help, try with forEach instead of .keys
        var sequenceNumberArray: [UInt16] = []
        rtpControlDataList.forEach { index, data in
            sequenceNumberArray.append(index)
        }

        sequenceNumberArray.sort() { $0 < $1 } // TODO: delete when set datatype is available

        var sequenceArray: [RTPSequence] = []

        //

        var maxJitter: Int64 = 0
        var meanJitter: Int64 = 0
        var skew: Int64 = 0
        var maxDelta: Int64 = 0
        var tsDiff: Int64 = 0

        //

        var prevSeqNr: UInt16? = nil
        for x in sequenceNumberArray {
            if let j = rtpControlDataList[x] {
                // println("prevSeqNr: \(prevSeqNr)")
                // println("jitterMap: \(jitterMap)")

                if let _prevSeqNr = prevSeqNr,
                    let i = rtpControlDataList[_prevSeqNr] {

                    tsDiff = Int64(j.receivedNS) - Int64(i.receivedNS)

                    var jitter: Double = 0.0
                    let delta = Int64(abs(calculateDelta(i, j, testObject.sampleRate)))
                    
                    if let prevJitter = jitterMap[_prevSeqNr] {
                        jitter = prevJitter + (Double(delta) - prevJitter) / 16
                    }

                    jitterMap[x] = jitter

                    maxDelta = max(delta, maxDelta)

                    let timestampDiff = Int64(j.rtpPacket.header.timestamp) - Int64(i.rtpPacket.header.timestamp)
                    skew += Int64((Double(timestampDiff) / Double(testObject.sampleRate) * 1000) * Double(NSEC_PER_MSEC)) - Int64(tsDiff)
                    maxJitter = max(Int64(jitter), maxJitter)
                    meanJitter += Int64(jitter)
                } else {
                    jitterMap[x] = 0
                }

                prevSeqNr = x
                sequenceArray.append(RTPSequence(timestampNS: j.receivedNS, seq: x))
                sequenceArray.sort() { $0.timestampNS < $1.timestampNS } // TODO: delete when set datatype is available
            }
        }

        //

        var nextSeq = initialSequenceNumber!
        var packetsOutOfOrder = 0
        var maxSequential = 0
        var minSequential = 0
        var curSequential = 0

        //

        var prevSeguence = sequenceNumberArray.first
        for i in sequenceNumberArray {
            if i - (prevSeguence ?? 0) > 1 {
                packetsOutOfOrder += 1
            }
            prevSeguence = i
        }
//        for i in sequenceArray {
//            if i.seq != nextSeq {
//                packetsOutOfOrder += 1
//
//                maxSequential = max(curSequential, maxSequential)
//
//                if curSequential > 1 {
//                    minSequential = (curSequential < minSequential) ? curSequential : (minSequential == 0 ? curSequential : minSequential)
//                }
//
//                curSequential = 0
//            } else {
//                curSequential += 1
//            }
//
//            nextSeq += 1
//        }

        maxSequential = Int(sequenceNumberArray.last ?? 0)
        minSequential = Int(sequenceNumberArray.first ?? 0)
//        maxSequential = max(curSequential, maxSequential)
//        if curSequential > 1 {
//            minSequential = (curSequential < minSequential) ? curSequential : (minSequential == 0 ? curSequential : minSequential)
//        }
//
//        if minSequential == 0 && maxSequential > 0 {
//            minSequential = maxSequential
//        }

        //

        return RTPResult(
            jitterMap: jitterMap,
            maxJitter: maxJitter,
            meanJitter: meanJitter / Int64(jitterMap.count),
            skew: skew,
            maxDelta: maxDelta,
            outOfOrder: UInt16(packetsOutOfOrder),
            minSequential: UInt16(maxSequential),
            maxSequential: UInt16(minSequential)
        )
    }

    ///
    private func calculateDelta(_ i: RTPControlData, _ j: RTPControlData, _ sampleRate: UInt16) -> Int64 {
        let msDiff: Int64 = Int64(j.receivedNS) - Int64(i.receivedNS)
        let timestampDiff = Int64(j.rtpPacket.header.timestamp) - Int64(i.rtpPacket.header.timestamp)
        let tsDiff: Int64 = Int64((Double(timestampDiff) / Double(sampleRate) * 1000) * Double(NSEC_PER_MSEC))

        return msDiff - tsDiff
    }

    private func updateProgress(packetNumber: UInt16) {
        let timeProgress: Float = Float(UInt64.getTimeDifferenceInNanoSeconds(self.testStartTimeTicks)) /   Float(self.testObject.timeout)
        let packetProgress: Float = Float(packetNumber) / Float(self.numPackets)
        if timeProgress > packetProgress {
            self.progressCallback(self, timeProgress)
        } else {
            self.progressCallback(self, packetProgress)
        }
    }
// MARK: QOSControlConnectionDelegate methods

    ///
    override func controlConnection(_ connection: QOSControlConnection, didReceiveTaskResponse response: String, withTaskId taskId: UInt, tag: Int) {
        qosLog.debug("CONTROL CONNECTION DELEGATE FOR TASK ID \(taskId), WITH TAG \(tag), WITH STRING \(response)")

        switch tag {
            case TAG_TASK_VOIPTEST:
                qosLog.debug("TAG_TASK_VOIPTEST response: \(response)")

                if response.hasPrefix("OK") {
                    TAG_TASK_VOIPTEST_cdl.countDown()

                    ssrc = UInt32(response.components(separatedBy: " ")[1]) // !
                    qosLog.info("got ssrc: \(ssrc ?? 0)")

                    let queue = DispatchQueue(label: "Voip startOutgoingTest queue")
                    queue.async {
                        self.startOutgoingTest()
                    }
                }

            case TAG_TASK_VOIPRESULT:
                qosLog.debug("TAG_TASK_VOIPRESULT response: \(response)")

                if response.hasPrefix("VOIPRESULT") {

                    let voipResultArray = response.components(separatedBy: " ") // split(response) { $0 == " " }

                    if voipResultArray.count >= 9 {
                        TAG_TASK_VOIPRESULT_cdl.countDown()

                        let prefix = RESULT_VOIP_PREFIX + RESULT_VOIP_PREFIX_OUTGOING

                        testResult.set(prefix + RESULT_VOIP_MAX_JITTER,         number: Int(voipResultArray[1]))
                        testResult.set(prefix + RESULT_VOIP_MEAN_JITTER,        number: Int(voipResultArray[2]))
                        testResult.set(prefix + RESULT_VOIP_MAX_DELTA,          number: Int(voipResultArray[3]))
                        testResult.set(prefix + RESULT_VOIP_SKEW,               number: Int(voipResultArray[4]))
                        testResult.set(prefix + RESULT_VOIP_NUM_PACKETS,        number: Int(voipResultArray[5]))
                        testResult.set(prefix + RESULT_VOIP_SEQUENCE_ERRORS,    number: Int(voipResultArray[6]))
                        testResult.set(prefix + RESULT_VOIP_SHORT_SEQUENTIAL,   number: Int(voipResultArray[7]))
                        testResult.set(prefix + RESULT_VOIP_LONG_SEQUENTIAL,    number: Int(voipResultArray[8]))

                        finishOutgoingTest()
                    }
                }

            default:
                break
//                assert(false, "should never happen")
        }
    }

// MARK: UDPStreamSenderDelegate methods

    /// returns false if the class should stop
    func udpStreamSender(_ udpStreamSender: UDPStreamSender, didReceivePacket packetData: Data) -> Bool {
        // qosLog.debug("udpStreamSenderDidReceive: \(packetData)")

        let receivedNS = UInt64.nanoTime()

        
        // assemble rtp packet
        if let rtpPacket = RTPPacket.fromData(packetData) {
            // put packet in data list
            uniqueQueue.sync {
                NSLog("======Receive===========sequenceNumber=======\(rtpPacket.header.sequenceNumber)")
                rtpControlDataList[rtpPacket.header.sequenceNumber] = RTPControlData(rtpPacket: rtpPacket, receivedNS: receivedNS)
            }
            // !! TODO: EXC_BAD_ACCESS at this line?
        }

        return true
    }

    /// returns false if the class should stop
    func udpStreamSender(_ udpStreamSender: UDPStreamSender, willSendPacketWithNumber packetNumber: UInt16, data: NSMutableDataPointer) -> Bool {
        if hasFinished {
            return false
        }
        if let initialRTPPacket = self.initialRTPPacket {
        var packet = initialRTPPacket
        if packetNumber > 0 {
            packet.header.increaseSequenceNumberBy(1)
            packet.header.increaseTimestampBy(payloadTimestamp)
            packet.header.marker = 0
        } else {
            packet.header.marker = 1
        }
        // generate random bytes

            self.updateProgress(packetNumber: packet.header.sequenceNumber)
//        let payloadBytes = UnsafeMutableRawPointer.allocate(byteCount: payloadSize, alignment: 0)
//        let customDealocator = Data.Deallocator.custom { (ptr, length) in
//            ptr.deallocate()
//        }
//        let payload = Data(bytesNoCopy: payloadBytes, count: payloadSize, deallocator: Data.Deallocator.free)
        
//        let payload = Data(bytes: payloadBytes, count: payloadSize)
        
//        initialRTPPacket.payload = payload
//        packet.payload = Data(bytes: [192, 108, 18, 0, 0, 96, 0, 0])
        
        var payloadBytes = malloc(payloadSize) // CAUTION! this sends memory dump to server...
//        memset(payloadBytes, 0, payloadSize)
        packet.payload = Data(buffer: UnsafeBufferPointer(start: &payloadBytes, count: 1))
        // Data(bytes: UnsafePointer<UInt8>(&payloadBytes), count: Int(payloadSize))
        free(payloadBytes)

        //

            self.initialRTPPacket = packet
        data?.pointee.append(self.initialRTPPacket.toData())
        
        
//        payloadBytes.deallocate()
            return true
        }
        else {
            return false
        }
        
    }

    ///
    func udpStreamSender(_ udpStreamSender: UDPStreamSender, didBindToPort port: UInt16) {
        testResult.set(RESULT_VOIP_IN_PORT, number: port)
    }

    func udpStreamSenderDidClose(_ udpStreamSender: UDPStreamSender, with error: Error?) {
        //Nothing, because udp socket will close by timeout. It's ok
    }
}
