/*****************************************************************************************************
 * Copyright 2016 SPECURE GmbH
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
import ObjectMapper

///
open class SettingsReponse: BasicResponse {

    ///
    var settings: Settings?

    ///
    var client: ClientSettings?

    ///
    var qosMeasurementTypes: [QosMeasurementResultResponse.MeasurementQosResultDetailTestDescription]? // TODO: shorten class names

    ///
    override open func mapping(map: Map) {
        super.mapping(map: map)

        settings <- map["settings"]
        client <- map["client"]
        qosMeasurementTypes <- map["qosMeasurementTypes"]
    }

    ///
    class Settings: Mappable {

        ///
        var controlServerIpv4Host: String?

        ///
        var controlServerIpv6Host: String?

        ///
        var downloadThreshold: String?

        ///
        var uploadThreshold: String?

        ///
        var advertisedSpeedsEnabled = false

        ///
        var advertisedSpeeds: [AdvertisedSpeed]?

        ///
        var rmbt: RmbtSettings?

        ///
        var urls: UrlSettings?

        ///
        var mapServer: MapServerSettings?

        ///
        var versions: VersionSettings?

        ///
        init() {

        }

        ///
        required init?(map: Map) {

        }

        ///
        func mapping(map: Map) {
            controlServerIpv4Host   <- map["controlServerIpv4Host"]
            controlServerIpv6Host   <- map["controlServerIpv6Host"]
            downloadThreshold       <- map["downloadThreshold"]
            uploadThreshold         <- map["uploadThreshold"]
            advertisedSpeedsEnabled <- map["advertisedSpeedsEnabled"]
            advertisedSpeeds        <- map["advertisedSpeeds"]
            rmbt        <- map["rmbt"]
            urls        <- map["urls"]
            mapServer   <- map["mapServer"]
            versions    <- map["versions"]
        }

        ///
        class AdvertisedSpeed: Mappable {

            ///
            var name: String?

            ///
            var enabled = false

            ///
            var minDownloadKbps: Int?

            ///
            var maxDownloadKbps: Int?

            ///
            var minUploadKbps: Int?

            ///
            var maxUploadKbps: Int?

            ///
            init() {

            }

            ///
            required init?(map: Map) {

            }

            ///
            func mapping(map: Map) {
                name            <- map["name"]
                enabled         <- map["enabled"]
                minDownloadKbps <- map["minDownloadKbps"]
                maxDownloadKbps <- map["maxDownloadKbps"]
                minUploadKbps   <- map["minUploadKbps"]
                maxUploadKbps   <- map["maxUploadKbps"]
            }
        }

        ///
        class RmbtSettings: Mappable {

            ///
            var duration: Int?

            ///
            var numThreads: Int?

            ///
            var numPings: Int?

            ///
            var geoAccuracyButtonLimit: Int?

            ///
            var geoAccuracyDetailLimit: Int?

            ///
            var geoDistanceDetailLimit: Int?

            ///
            init() {

            }

            ///
            required init?(map: Map) {

            }

            ///
            func mapping(map: Map) {
                duration    <- map["duration"]
                numThreads  <- map["numThreads"]
                numPings    <- map["numPings"]
                geoAccuracyButtonLimit <- map["geoAccuracyButtonLimit"]
                geoAccuracyDetailLimit <- map["geoAccuracyDetailLimit"]
                geoDistanceDetailLimit <- map["geoDistanceDetailLimit"]
            }
        }

        ///
        class UrlSettings: Mappable {

            ///
            var ipv4IpCheck: String?

            ///
            var ipv6IpCheck: String?

            ///
            var statistics: String?

            ///
            var opendataPrefix: String?

            ///
            init() {

            }

            ///
            required init?(map: Map) {

            }

            ///
            func mapping(map: Map) {
                ipv4IpCheck     <- map["ipv4IpCheck"]
                ipv6IpCheck     <- map["ipv6IpCheck"]
                statistics      <- map["statistics"]
                opendataPrefix  <- map["opendataPrefix"]
            }
        }


        
        class VersionSettings: Mappable {
            
            ///
            var controlServerVersion: String?
            
            ///
            init() {
                
            }
            
            ///
            required init?(map: Map) {
                
            }
            
            ///
            func mapping(map: Map) {
                controlServerVersion <- map["controlServerVersion"]
            }
        }
    }
}

///
open class MapServerSettings: Mappable {
    
    ///
    var host: String?
    
    ///
    var port: Int?
    
    ///
    var useTls = true
    
    ///
    public init() {
        
    }
    
    ///
    required public init?(map: Map) {
        
    }
    
    ///
    public func mapping(map: Map) {
        host    <- map["host"]
        port    <- map["port"]
        useTls  <- map["useSsl"]
    }
}

///
