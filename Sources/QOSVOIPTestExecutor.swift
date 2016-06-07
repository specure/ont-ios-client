//
//  QOSVOIPTestExecutor.swift
//  RMBT
//
//  Created by Benjamin Pucher on 29.01.15.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

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
    private var rtpControlDataList = [UInt16: RTPControlData]()

    ///
    private var payloadSize: Int!

    ///
    private var payloadTimestamp: UInt32!

    ///
    private var cdl: CountDownLatch!

    //

    ///
    override init(controlConnection: QOSControlConnection, delegateQueue: dispatch_queue_t, testObject: T, speedtestStartTime: UInt64) {
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
        testResult.set(RESULT_VOIP_STATUS,          value: "OK") // !
        testResult.set(RESULT_VOIP_TIMEOUT,         number: testObject.timeout)

        initialSequenceNumber = UInt16(arc4random_uniform(10000) + 1)
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
        voipCommand += "\(initialSequenceNumber) \(testObject.payloadType)"

        sendTaskCommand(voipCommand, withTimeout: timeoutInSec, tag: TAG_TASK_VOIPTEST)

        cdlTimeout(500, forTag: "TAG_TASK_VOIPTEST")
    }

    ///
    override func testDidSucceed() {
        super.testDidSucceed()
    }

    ///
    override func testDidTimeout() {
        testResult.set(RESULT_VOIP_STATUS, value: "TIMEOUT")

        udpStreamSender?.stop()

        super.testDidTimeout()
    }

    ///
    override func testDidFail() {
        testResult.set(RESULT_VOIP_STATUS, value: "ERROR")

        udpStreamSender?.stop()

        super.testDidFail()
    }

// MARK: Other methods

    func cdlTimeout(timeoutMs: UInt64, forTag: String) {
        cdl = CountDownLatch()
        let noTimeout = cdl.await(timeoutMs * NSEC_PER_MSEC)
        cdl = nil
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

        let dDelay          = Double(testObject.delay / NSEC_PER_MSEC)
        let dSampleRate     = Double(testObject.sampleRate)
        let dBitsPerSample  = Double(testObject.bitsPerSample)
        let dCallDuration   = Double(testObject.callDuration / NSEC_PER_MSEC)
        let numPackets      = UInt16(dCallDuration / dDelay)

        qosLog.debug("dDelay: \(dDelay)")
        qosLog.debug("dSampleRate: \(dSampleRate)")
        qosLog.debug("dBitsPerSample: \(dBitsPerSample)")
        qosLog.debug("dCallDuration: \(dCallDuration)")
        qosLog.debug("numPackets: \(numPackets)")

        //

        payloadSize         = Int(dSampleRate / (1000 / dDelay) * (dBitsPerSample / 8))
        payloadTimestamp    = UInt32(dSampleRate / (1000 / dDelay))

        qosLog.debug("payloadSize: \(payloadSize)")
        qosLog.debug("payloadTimestamp: \(payloadTimestamp)")

        //

        initialRTPPacket = RTPPacket()

        initialRTPPacket.header.payloadType = testObject.payloadType
        initialRTPPacket.header.ssrc = ssrc
        initialRTPPacket.header.sequenceNumber = initialSequenceNumber

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

        udpStreamSender = UDPStreamSender(settings: settings)
        udpStreamSender.delegate = self

        // start timeout timer
        startTimer()

        qosLog.debug("before send udpStreamSender")

        let ticksBeforeSend = getCurrentTimeTicks()

        let boolOk = udpStreamSender.send()

        qosLog.debug("after send udpStreamSender (-> \(boolOk)) (took \(Double(getTimeDifferenceInNanoSeconds(ticksBeforeSend)) / Double(NSEC_PER_MSEC))ms)")

        udpStreamSender.stop()

        // stop timeout timer
        stopTimer()

        // timeout if sender ran into timeout
        if !boolOk {
            testDidTimeout()
            return
        }

        // request results
        // wait short time (last udp packet could reach destination after this request resulting in strange server behaviour)
        usleep(100000) /* 100 * 1000 */

        controlConnection.sendTaskCommand("GET VOIPRESULT \(ssrc)", withTimeout: timeoutInSec, forTaskId: testObject.qosTestId, tag: TAG_TASK_VOIPRESULT)

        cdlTimeout(500, forTag: "TAG_TASK_VOIPRESULT")
    }

    ///
    private func finishOutgoingTest() {
        qosLog.debug("FINISH OUTGOING VOIP TEST")

        let prefix = RESULT_VOIP_PREFIX + RESULT_VOIP_PREFIX_INCOMING

        let _start = getCurrentTimeTicks()
        qosLog.debug("_calculateQOS start")

        // calculate QOS
        if let rtpResult = calculateQOS() {

            qosLog.debug("_calculateQOS took \(getTimeDifferenceInNanoSeconds(_start) / NSEC_PER_MSEC) ms")

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

        if rtpControlDataList.count == 0 {
            return nil
        }

        //

        var jitterMap = [UInt16: Double]()
        
        var sequenceNumberArray = [UInt16](rtpControlDataList.keys) // TODO: fatal error? TODO! also occured on 2016-06-07 14:09
        sequenceNumberArray.sortInPlace() { $0 < $1 } // TODO: delete when set datatype is available

        var sequenceArray = [RTPSequence]()
        // sort(&sequenceArray) { $0.timestampNS < $1.timestampNS }  // TODO: delete when set datatype is available

        //

        var maxJitter: Int64 = 0
        var meanJitter: Int64 = 0
        var skew: Int64 = 0
        var maxDelta: Int64 = 0
        var tsDiff: Int64 = 0

        //

        var prevSeqNr: UInt16? = nil
        for x in sequenceNumberArray {
            let j = rtpControlDataList[x]!

            // println("prevSeqNr: \(prevSeqNr)")
            // println("jitterMap: \(jitterMap)")

            if let _prevSeqNr = prevSeqNr {
                let i = rtpControlDataList[_prevSeqNr]!

                tsDiff = Int64(j.receivedNS) - Int64(i.receivedNS)

                let prevJitter: Double = jitterMap[_prevSeqNr]!
                let delta: Int64 = Int64(abs(calculateDelta(i, j, testObject.sampleRate)))
                let jitter: Double = prevJitter + (Double(delta) - prevJitter) / 16

                jitterMap[x] = jitter

                maxDelta = max(delta, maxDelta)

                skew += Int64((Double(j.rtpPacket.header.timestamp - i.rtpPacket.header.timestamp) / Double(testObject.sampleRate) * 1000) * Double(NSEC_PER_MSEC)) - Int64(tsDiff)
                maxJitter = max(Int64(jitter), maxJitter)
                meanJitter += Int64(jitter)
            } else {
                jitterMap[x] = 0
            }

            prevSeqNr = x
            sequenceArray.append(RTPSequence(timestampNS: j.receivedNS, seq: x))
            sequenceArray.sortInPlace() { $0.timestampNS < $1.timestampNS } // TODO: delete when set datatype is available
        }

        //

        var nextSeq = initialSequenceNumber!
        var packetsOutOfOrder = 0
        var maxSequential = 0
        var minSequential = 0
        var curSequential = 0

        //

        for i in sequenceArray {
            if i.seq != nextSeq {
                packetsOutOfOrder += 1

                maxSequential = max(curSequential, maxSequential)

                if curSequential > 1 {
                    minSequential = (curSequential < minSequential) ? curSequential : (minSequential == 0 ? curSequential : minSequential)
                }

                curSequential = 0
            } else {
                curSequential += 1
            }

            nextSeq += 1
        }

        maxSequential = max(curSequential, maxSequential)
        if curSequential > 1 {
            minSequential = (curSequential < minSequential) ? curSequential : (minSequential == 0 ? curSequential : minSequential)
        }

        if minSequential == 0 && maxSequential > 0 {
            minSequential = maxSequential
        }

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
    private func calculateDelta(i: RTPControlData, _ j: RTPControlData, _ sampleRate: UInt16) -> Int64 {
        let msDiff: Int64 = Int64(j.receivedNS) - Int64(i.receivedNS)
        let tsDiff: Int64 = Int64((Double(j.rtpPacket.header.timestamp - i.rtpPacket.header.timestamp) / Double(sampleRate) * 1000) * Double(NSEC_PER_MSEC))

        return msDiff - tsDiff
    }

// MARK: QOSControlConnectionDelegate methods

    ///
    override func controlConnection(connection: QOSControlConnection, didReceiveTaskResponse response: String, withTaskId taskId: UInt, tag: Int) {
        qosLog.debug("CONTROL CONNECTION DELEGATE FOR TASK ID \(taskId), WITH TAG \(tag), WITH STRING \(response)")

        switch tag {
            case TAG_TASK_VOIPTEST:
                qosLog.debug("TAG_TASK_VOIPTEST response: \(response)")

                if response.hasPrefix("OK") {
                    cdl?.countDown()

                    ssrc = UInt32(response.componentsSeparatedByString(" ")[1]) // !
                    qosLog.info("got ssrc: \(ssrc)")

                    startOutgoingTest()
                }

            case TAG_TASK_VOIPRESULT:
                qosLog.debug("TAG_TASK_VOIPRESULT response: \(response)")

                if response.hasPrefix("VOIPRESULT") {

                    let voipResultArray = response.componentsSeparatedByString(" ") // split(response) { $0 == " " }

                    if voipResultArray.count >= 9 {
                        cdl?.countDown()

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
                assert(false, "should never happen")
        }
    }

// MARK: UDPStreamSenderDelegate methods

    /// returns false if the class should stop
    func udpStreamSender(udpStreamSender: UDPStreamSender, didReceivePacket packetData: NSData) -> Bool {
        // qosLog.debug("udpStreamSenderDidReceive: \(packetData)")

        let receivedNS = nanoTime()

        // assemble rtp packet
        if let rtpPacket = RTPPacket.fromData(packetData) {

            // put packet in data list
            rtpControlDataList[rtpPacket.header.sequenceNumber] = RTPControlData(rtpPacket: rtpPacket, receivedNS: receivedNS)
            // !! TODO: EXC_BAD_ACCESS at this line?
        }

        return true
    }

    /// returns false if the class should stop
    func udpStreamSender(udpStreamSender: UDPStreamSender, willSendPacketWithNumber packetNumber: UInt16, inout data: NSMutableData) -> Bool {
        if packetNumber > 0 {
            initialRTPPacket.header.increaseSequenceNumberBy(1)
            initialRTPPacket.header.increaseTimestampBy(payloadTimestamp)
            initialRTPPacket.header.marker = 0
        } else {
            initialRTPPacket.header.marker = 1
        }

        // generate random bytes

        var payloadBytes = malloc(payloadSize) // CAUTION! this sends memory dump to server...
        initialRTPPacket.payload = NSData(bytes: &payloadBytes, length: Int(payloadSize))
        free(payloadBytes)

        //

        data.appendData(initialRTPPacket.toData())

        return true
    }

    ///
    func udpStreamSender(udpStreamSender: UDPStreamSender, didBindToPort port: UInt16) {
        testResult.set(RESULT_VOIP_IN_PORT, number: port)
    }

}
