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
class QOSVOIPTest: QOSTest {

    private let PARAM_BITS_PER_SAMLE = "bits_per_sample"
    private let PARAM_SAMPLE_RATE = "sample_rate"
    private let PARAM_DURATION = "call_duration" //call duration in ns
    private let PARAM_PORT_OUT = "out_port"
    private let PARAM_PORT_IN = "in_port"
    private let PARAM_DELAY = "delay"
    private let PARAM_PAYLOAD = "payload"

    // TODO: parameter list not final

    var portOut: UInt16?
    var portIn: UInt16?

    var delay: UInt64 = 20_000_000 // 20ms
    var callDuration: UInt64 = 1_000_000_000 // 1s

    var sampleRate: UInt16 = 8000 // 8 kHz
    var bitsPerSample: UInt8 = 8

    var payloadType: UInt8 = 8 // PCMA(8, 8000, 1, CodecType.AUDIO)

    //

    ///
    override var description: String {
        return super.description + ", [outgoingPort: \(String(describing: portOut)), incomingPort: \(String(describing: portIn)), callDuration: \(callDuration), delay: \(delay), sampleRate: \(sampleRate), bitsPerSample: \(bitsPerSample)]"
    }

    //

    ///
    override init(testParameters: QOSTestParameters) {
        // TODO: parse testParameters

        // portOut
        if let portOutString = testParameters[PARAM_PORT_OUT] as? String {
            if let portOut = UInt16(portOutString) {
                self.portOut = portOut
                // Log.logger.debug("setting portOut: \(self.portOut)")
            }
        }

        // portIn
        if let portInString = testParameters[PARAM_PORT_IN] as? String {
            if let portIn = UInt16(portInString) {
                self.portIn = portIn
                // Log.logger.debug("setting portIn: \(self.portIn)")
            } else {
                self.portIn = self.portOut  // use outPort also as inPort if no inPort was set
            }
        }

        // delay
        if let delayString = testParameters[PARAM_DELAY] as? NSString {
            let delay = delayString.longLongValue
            if delay > 0 {
                self.delay = UInt64(delay)
                // Log.logger.debug("setting delay: \(self.delay)")
            }
        }

        // callDuration
        if let callDurationString = testParameters[PARAM_DURATION] as? NSString {
            let callDuration = callDurationString.longLongValue
            if callDuration > 0 {
                self.callDuration = UInt64(callDuration)
                // Log.logger.debug("setting callDuration: \(self.callDuration)")
            }
        }

        // sampleRate
        if let sampleRateString = testParameters[PARAM_SAMPLE_RATE] as? String {
            if let sampleRate = UInt16(sampleRateString) {
                self.sampleRate = sampleRate
                // Log.logger.debug("setting sampleRate: \(self.sampleRate)")
            }
        }

        // bitsPerSample
        if let bitsPerSampleString = testParameters[PARAM_BITS_PER_SAMLE] as? String {
            if let bitsPerSample = UInt8(bitsPerSampleString) {
                self.bitsPerSample = bitsPerSample
                // Log.logger.debug("setting bitsPerSample: \(self.bitsPerSample)")
            }
        }

        // payloadType
        if let payloadTypeString = testParameters[PARAM_PAYLOAD] as? String {
            if let payloadType = UInt8(payloadTypeString) {
                self.payloadType = payloadType
                // Log.logger.debug("setting payloadType: \(self.payloadType)")
            }
        }

        super.init(testParameters: testParameters)
    }

    ///
    override func getType() -> QosMeasurementType! {
        return .VOIP
    }

}
