//
//  QOSConfig.swift
//  RMBT
//
//  Created by Benjamin Pucher on 06.02.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import CocoaAsyncSocket

//////////////////
// QOS
//////////////////

/// default qos socket character encoding
let QOS_SOCKET_DEFAULT_CHARACTER_ENCODING: UInt = NSUTF8StringEncoding

///
let QOS_CONTROL_CONNECTION_TIMEOUT_NS: UInt64 = 10_000_000_000
let QOS_CONTROL_CONNECTION_TIMEOUT_SEC = NSTimeInterval(QOS_CONTROL_CONNECTION_TIMEOUT_NS / NSEC_PER_SEC)

///
let QOS_DEFAULT_TIMEOUT_NS: UInt64 = 10_000_000_000 // default timeout value in nano seconds

///
let QOS_TLS_SETTINGS: [String:AnyObject] = [
    GCDAsyncSocketManuallyEvaluateTrust: true
]

///
let WALLED_GARDEN_URL: String = "http://nettest.specure.com/generate_204" // TODO: use url from settings request

///
let WALLED_GARDEN_SOCKET_TIMEOUT_MS: Double = 10_000

///
#if DEBUG

let QOS_ENABLED_TESTS: [QOSMeasurementType] = [
    .HttpProxy,
    .NonTransparentProxy,
    //.WEBSITE,
    .DNS,
    .TCP,
    .UDP,
    .VOIP,
    .TRACEROUTE
]

/// determine the tests which should show log messages
let QOS_ENABLED_TESTS_LOG: [QOSMeasurementType] = [
//    .HttpProxy,
//    .NonTransparentProxy,
//    .WEBSITE,
//    .DNS,
//    .TCP,
//    .UDP,
    .VOIP,
//    .TRACEROUTE
]

#else

// BETA / PRODUCTION

let QOS_ENABLED_TESTS: [QOSMeasurementType] = [
    .HttpProxy,
    .NonTransparentProxy,
    //.WEBSITE,
    .DNS,
    .TCP,
    .UDP,
    .VOIP,
    .TRACEROUTE
]

/// determine the tests which should show log messages
let QOS_ENABLED_TESTS_LOG: [QOSMeasurementType] = [
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
