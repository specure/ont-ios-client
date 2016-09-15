//
//  RMBTConfig.swift
//  RMBT
//
//  Created by Tomáš Baculák on 14/01/15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import CoreLocation

// MARK: Fixed test parameters

///
let RMBT_TEST_SOCKET_TIMEOUT_S = 30.0

/// Maximum number of tests to perform in loop mode
let RMBT_TEST_LOOPMODE_LIMIT = 100

///
let RMBT_TEST_LOOPMODE_WAIT_BETWEEN_RETRIES_S = 5

///
let RMBT_TEST_PRETEST_MIN_CHUNKS_FOR_MULTITHREADED_TEST = 4

///
let RMBT_TEST_PRETEST_DURATION_S = 2.0

///
let RMBT_TEST_PING_COUNT = 10

/// In case of slow upload, we finalize the test even if this many seconds still haven't been received:
let RMBT_TEST_UPLOAD_MAX_DISCARD_S = 1.0

/// Minimum number of seconds to wait after sending last chunk, before starting to discard.
let RMBT_TEST_UPLOAD_MIN_WAIT_S    = 0.25

/// Maximum number of seconds to wait for server reports after last chunk has been sent.
/// After this interval we will close the socket and finish the test on first report received.
let RMBT_TEST_UPLOAD_MAX_WAIT_S    = 3

/// Measure and submit speed during test in these intervals
let RMBT_TEST_SAMPLING_RESOLUTION_MS = 250

///
let RMBT_CONTROL_SERVER_PATH = "/RMBTControlServer"

///
let RMBT_MAP_SERVER_PATH = "/RMBTMapServer"

// MARK: Default control server URLs

let RMBT_CONTROL_SERVER_URL        = "https://nettest.specure.com\(RMBT_CONTROL_SERVER_PATH)"
let RMBT_CONTROL_SERVER_IPV4_URL   = "https://nettest4.specure.com\(RMBT_CONTROL_SERVER_PATH)"
let RMBT_CONTROL_SERVER_IPV6_URL   = "https://nettest6.specure.com\(RMBT_CONTROL_SERVER_PATH)"

// MARK:- Other URLs used in the app

let RMBT_URL_HOST = "https://nettest.specure.com"

/// Note: $lang will be replaced by the device language (de, en, sl, etc.)
let RMBT_STATS_URL       = "\(RMBT_URL_HOST)/$lang/statistics"
let RMBT_HELP_URL        = "\(RMBT_URL_HOST)/$lang/help"
let RMBT_HELP_RESULT_URL = "\(RMBT_URL_HOST)/$lang/help"

let RMBT_PRIVACY_TOS_URL = "\(RMBT_URL_HOST)/$lang/tc"

//

let RMBT_ABOUT_URL       = "https://specure.com"
let RMBT_PROJECT_URL     = RMBT_URL_HOST
let RMBT_PROJECT_EMAIL   = "nettest@specure.com"

let RMBT_REPO_URL        = "https://github.com/specure"
let RMBT_DEVELOPER_URL   = "https://specure.com"

// MARK: Map options

let RMBT_MAP_SERVER_URL = "https://nettest.specure.com\(RMBT_MAP_SERVER_PATH)"

/// Initial map center coordinates and zoom level
let RMBT_MAP_INITIAL_LAT: CLLocationDegrees = 48.209209 // Stephansdom, Wien
let RMBT_MAP_INITIAL_LNG: CLLocationDegrees = 16.371850

let RMBT_MAP_INITIAL_ZOOM: Float = 12.0

/// Zoom level to use when showing a test result location
let RMBT_MAP_POINT_ZOOM: Float = 12.0

/// In "auto" mode, when zoomed in past this level, map switches to points
let RMBT_MAP_AUTO_TRESHOLD_ZOOM: Float = 12.0

// Google Maps API Key

///#warning Please supply a valid Google Maps API Key. See https://developers.google.com/maps/documentation/ios/start#the_google_maps_api_key
let RMBT_GMAPS_API_KEY = "AIzaSyDCoFuxghaMIVOKEeGxeGInAiWo9A0iJL4"

// MARK: Misc

/// Current TOS version. Bump to force displaying TOS to users again.
let RMBT_TOS_VERSION = 1

///////////////////

let TEST_SHOW_TRAFFIC_WARNING_ON_CELLULAR_NETWORK = false
let TEST_SHOW_TRAFFIC_WARNING_ON_WIFI_NETWORK = false

let TEST_USE_PERSONAL_DATA_FUZZING = false

// If set to false: Statistics is not visible, tap on map points doesn't show bubble, ...
let USE_OPENDATA = true
