/*****************************************************************************************************
 * Copyright 2013 appscape gmbh
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

import CoreLocation

// MARK: Test parameters Variables
//
public let LANGUAGE_PREFIX = "$lang"
//
public let DEFAULT_LANGUAGE = "en"
//
public let PREFFERED_LANGUAGE = Bundle.main.preferredLocalizations.first ?? DEFAULT_LANGUAGE

public class RMBTConfig {
    
    public enum SettingsMode {
        case urlsLocally
        case remotely
    }
//    // ID = 1 is a Server placed in Nurmberg
//    var defaultMeasurementServerId:UInt64 = 1
    
    //
    public static let sharedInstance: RMBTConfig = {
        let config = RMBTConfig()
        LogConfig.initLoggingFramework()
        return config
    } ()
    
    //
    public init() {}

    // MARK: Default control server URLs   // CouchDB as Default disabled 
    var RMBT_CONTROL_SERVER_URL        = "\(RMBT_URL_HOST)\(RMBT_CONTROL_SERVER_PATH)" // = "https://netcouch.specure.com\(RMBT_CONTROL_SERVER_SUFFIX)"
    
    var RMBT_CONTROL_MEASUREMENT_SERVER_URL        = "\(RMBT_URL_HOST)\(RMBT_CONTROL_MEASUREMENT_SERVER_PATH)"
    //
    var RMBT_CONTROL_SERVER_IPV4_URL   = "\(RMBT_URL_HOST)\(RMBT_CONTROL_SERVER_PATH)" // "https://netcouch.specure.com\(RMBT_CONTROL_SERVER_SUFFIX)"
    //
    var RMBT_CONTROL_SERVER_IPV6_URL   = "\(RMBT_URL_HOST)\(RMBT_CONTROL_SERVER_PATH)"// "https://netcouch.specure.com\(RMBT_CONTROL_SERVER_SUFFIX)"
    //
    var RMBT_MAP_SERVER_PATH_URL       = "https://netcouch.specure.com\(RMBT_MAP_SERVER_PATH)"
    //
    var RMBT_CHECK_IPV4_URL            = "https://netcouch.specure.com\(RMBT_CONTROL_SERVER_PATH)/ip"
    
    // Server to be used for a measurement
    public var measurementServer: MeasurementServerInfoResponse.Servers?
    
    //
    public var RMBT_VERSION_NEW = false
    
    public var RMBT_DEFAULT_IS_CURRENT_COUNTRY = true
    
    public var RMBT_USE_MAIN_LANGUAGE = false
    public var RMBT_MAIN_LANGUAGE = "en"
    
    public var settingsMode: SettingsMode = .remotely
    
    //
    public func configNewCS(server: String) {
        RMBT_CONTROL_SERVER_URL = server.hasPrefix(secureRequestPrefix) ? server : secureRequestPrefix + server
    }
    //
    public func configNewMeasurementCS(server: String) {
        RMBT_CONTROL_MEASUREMENT_SERVER_URL = server.hasPrefix(secureRequestPrefix) ? server : secureRequestPrefix + server
    }
    //
    public func configNewCS_IPv4(server: String) {
        RMBT_CONTROL_SERVER_IPV4_URL  = server.hasPrefix(secureRequestPrefix) ? server : secureRequestPrefix + server
    }
    //
    public func configNewCS_IPv6(server: String) {
        RMBT_CONTROL_SERVER_IPV6_URL = server.hasPrefix(secureRequestPrefix) ? server : secureRequestPrefix + server
    }

    public func configNewCS_checkIPv4(server: String) {
        RMBT_CHECK_IPV4_URL = server.hasPrefix(secureRequestPrefix) ? server : secureRequestPrefix + server
    }
    
    //
    public func configNewMapServer(server: String) {
        RMBT_MAP_SERVER_PATH_URL = server.hasPrefix(secureRequestPrefix) ? server : secureRequestPrefix + server
        RMBT_MAP_SERVER_PATH_URL = RMBT_MAP_SERVER_PATH_URL.hasSuffix(RMBT_MAP_SERVER_PATH) ?
            RMBT_MAP_SERVER_PATH_URL
            :
            RMBT_MAP_SERVER_PATH_URL + RMBT_MAP_SERVER_PATH
    }
    
    //
    public func configNewSuffixMapServer(server: String) {
        RMBT_MAP_SERVER_PATH = server
    }
    
    public static func updateSettings(success successCallback: @escaping EmptyCallback, error failure: @escaping ErrorCallback) {
    
        ControlServer.sharedControlServer.updateWithCurrentSettings(success: {
            successCallback()
        }, error: { error in
            
            failure(error)
        })
    }
    
    public static func clearStoredUUID() {
        ControlServer.sharedControlServer.clearStoredUUID()
    }
    
    public static func updateAdvertisingSettings(success successCallback: @escaping EmptyCallback, error failure: @escaping ErrorCallback) {
        ControlServer.sharedControlServer.getAdvertising(success: successCallback, error: failure)
    }
}


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

let RMBT_CONTROL_MEASUREMENT_SERVER_PATH = "/RMBTControlServer/V2"

///
let RMBT_CONTROL_SERVER_SUFFIX = "/api/v1"

///
var RMBT_MAP_SERVER_PATH = "/RMBTMapServer"



// MARK:- Other URLs used in the app

let RMBT_URL_HOST = "https://qos01.akostest.net"

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

let RMBT_MAP_SERVER_URL = "\(RMBT_URL_HOST)\(RMBT_MAP_SERVER_PATH)"

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

let TEST_USE_PERSONAL_DATA_FUZZING = false

// If set to false: Statistics is not visible, tap on map points doesn't show bubble, ...
let USE_OPENDATA = true
