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

import CocoaAsyncSocket

//////////////////
// QOS
//////////////////

/// default qos socket character encoding
let QOS_SOCKET_DEFAULT_CHARACTER_ENCODING: UInt = String.Encoding.utf8.rawValue

///
let QOS_CONTROL_CONNECTION_TIMEOUT_NS: UInt64 = 10_000_000_000
let QOS_CONTROL_CONNECTION_TIMEOUT_SEC = TimeInterval(QOS_CONTROL_CONNECTION_TIMEOUT_NS / NSEC_PER_SEC)

///
let QOS_DEFAULT_TIMEOUT_NS: UInt64 = 10_000_000_000 // default timeout value in nano seconds

///
let QOS_TLS_SETTINGS: [String: NSNumber] = [
    GCDAsyncSocketManuallyEvaluateTrust: NSNumber(value: true as Bool)
]

///
let WALLED_GARDEN_URL: String = "http://nettest.org/generate_204" // TODO: use url from settings request

///
let WALLED_GARDEN_SOCKET_TIMEOUT_MS: Double = 10_000

///
#if DEBUG

let QOS_ENABLED_TESTS: [QosMeasurementType] = [
    .JITTER,
    .HttpProxy,
    .NonTransparentProxy,
    .WEBSITE,
    .DNS,
    .TCP,
    .UDP,
    .VOIP, //Must be uncommented. Without it we can't get jitter and packet loss
    .TRACEROUTE
]

/// determine the tests which should show log messages
let QOS_ENABLED_TESTS_LOG: [QosMeasurementType] = [
    .HttpProxy,
//    .NonTransparentProxy,
//    .WEBSITE,
//    .DNS,
//    .TCP,
//    .UDP,
    .VOIP, //Must be uncommented. Without it we can't get jitter and packet loss
//    .TRACEROUTE
]

#else

// BETA / PRODUCTION

let QOS_ENABLED_TESTS: [QosMeasurementType] = [
    .JITTER,
    .HttpProxy,
    .NonTransparentProxy,
    .WEBSITE,
    .DNS,
    .TCP,
    .UDP,
    .VOIP, //Must be uncommented. Without it we can't get jitter and packet loss
    .TRACEROUTE
]

/// determine the tests which should show log messages
let QOS_ENABLED_TESTS_LOG: [QosMeasurementType] = [
    .HttpProxy,
    .NonTransparentProxy,
    //    .WEBSITE,
    .DNS,
    .TCP,
    .UDP,
    .VOIP,
    .TRACEROUTE
]

#endif
