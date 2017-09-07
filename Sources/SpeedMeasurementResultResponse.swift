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
open class VoipTest: Mappable {
    
    open var voip_result_status:String?
    open var voip_result_in_short_seq  : NSNumber?
    open var voip_result_in_num_packets : NSNumber?
    open var voip_objective_bits_per_sample : NSNumber?
    open var voip_result_in_max_jitter  : NSNumber?
    open var voip_objective_delay  : NSNumber?
    open var voip_result_out_skew  : NSNumber?
    open var voip_objective_in_port : NSNumber?
    open var voip_result_out_short_seq  : NSNumber?
    open var voip_result_out_sequence_error : NSNumber?
    open var voip_result_jitter  : String?
    open var voip_objective_sample_rate : NSNumber?
    open var voip_objective_call_duration : NSNumber?
    open var voip_result_in_skew : NSNumber?
    open var voip_result_in_max_delta : NSNumber?
    open var duration_ns : NSNumber?
    open var voip_result_out_max_delta : NSNumber?
    open var voip_result_out_long_seq  : NSNumber?
    open var classification_packet_loss : NSNumber?
    open var voip_result_in_sequence_error : NSNumber?
    open var voip_result_out_mean_jitter : NSNumber?
    open var voip_result_out_max_jitter : NSNumber?
    open var voip_objective_payload : NSNumber?
    open var voip_result_in_mean_jitter : NSNumber?
    open var voip_result_in_long_seq : NSNumber?
    open var voip_result_packet_loss : String?
    open var start_time_ns : NSNumber?
    open var voip_objective_timeout : NSNumber?
    open var voip_result_out_num_packets : NSNumber?
    open var voip_objective_out_port : NSNumber?
    open var classification_jitter : NSNumber?
    
    ///
    init() {
        
    }
    
    ///
    required public init?(map: Map) {
        
    }
    
    ///
    open func mapping(map: Map) {
        
        voip_result_status <- map["voip_result_status"]
        voip_result_in_short_seq <- map["voip_result_in_short_seq"]
        voip_result_in_num_packets <- map[ "voip_result_in_num_packets"]
        voip_objective_bits_per_sample <- map[ "voip_objective_bits_per_sample"]
        voip_result_in_max_jitter <- map["voip_result_in_max_jitter"]
        voip_objective_delay <- map[ "voip_objective_delay"]
        voip_result_out_skew <- map[ "voip_result_out_skew"]
        voip_objective_in_port <- map[ "voip_objective_in_port"]
        voip_result_out_short_seq <- map[ "voip_result_out_short_seq"]
        voip_result_out_sequence_error <- map[ "voip_result_out_sequence_error"]
        voip_result_jitter <- map[ "voip_result_jitter"]
        voip_objective_sample_rate <- map[ "voip_objective_sample_rate"]
        voip_objective_call_duration <- map[ "voip_objective_call_duration"]
        voip_result_in_skew <- map[ "voip_result_in_skew"]
        voip_result_in_max_delta <- map[ "voip_result_in_max_delta"]
        duration_ns <- map[ "duration_ns"]
        voip_result_out_max_delta <- map[ "voip_result_out_max_delta"]
        voip_result_out_long_seq <- map[ "voip_result_out_long_seq"]
        classification_packet_loss <- map[ "classification_packet_loss"]
        voip_result_in_sequence_error <- map[ "voip_result_in_sequence_error"]
        voip_result_out_mean_jitter <- map[ "voip_result_out_mean_jitter"]
        voip_result_out_max_jitter <- map[ "voip_result_out_max_jitter"]
        voip_objective_payload <- map[ "voip_objective_payload"]
        voip_result_in_mean_jitter <- map[ "voip_result_in_mean_jitter"]
        voip_result_in_long_seq <- map[ "voip_result_in_long_seq"]
        voip_result_packet_loss <- map[ "voip_result_packet_loss"]
        start_time_ns <- map[ "start_time_ns"]
        voip_objective_timeout <- map[ "voip_objective_timeout"]
        voip_result_out_num_packets <- map[ "voip_result_out_num_packets"]
        voip_objective_out_port <- map[ "voip_objective_out_port"]
        classification_jitter <- map[ "classification_jitter"]
    }
}

///
open class SpeedMeasurementResultResponse: BasicResponse {
    
    /// ONT
    open var jpl:VoipTest?
    
    ///
    open var device:[ResultItem]?

    ///
    open var classifiedMeasurementDataList: [ClassifiedResultItem]?

    ///
    open var networkDetailList: [ResultItem]?

    ///
    open var networkType: Int?

    ///
    open var openTestUuid: String?

    ///
    open var openUuid: String?

    ///
    open var time: Int?

    ///
    open var timeString: String?

    ///
    open var timezone: String?

    ///
    open var location: String?

    ///
    open var latitude: Double?

    ///
    open var longitude: Double?

    ///
    open var shareText: String?

    ///
    open var shareSubject: String?

    //////////// only for map

    ///
    open var highlight = false

    ///
    open var measurementUuid: String?

    ////////////

    ///
    override open func mapping(map: Map) {
        super.mapping(map: map)
        
        jpl <- map["jpl"]
        device <- map["device"]

        classifiedMeasurementDataList <- map["measurement"]
        networkDetailList <- map["net"]

        networkType <- map["network_type"]

        openTestUuid <- map["open_test_uuid"]
        openUuid <- map["open_uuid"]
        time <- map["time"]
        timeString <- map["time_string"]
        timezone <- map["timezone"]
        location <- map["location"]
        latitude <- map["geo_lat"]
        longitude <- map["geo_long"]
        shareText <- map["share_text"]
        shareSubject <- map["share_subject"]

        // only for map
        highlight <- map["highlight"]
        measurementUuid <- map["measurement_uuid"]
    }

    ///
    override open var description: String {
        return "SpeedMeasurementResultResponse [\(String(describing: openTestUuid)),\(String(describing: latitude)),\(String(describing: longitude))]"
    }

    ///
    open class ResultItem: Mappable {

        ///
        open var value: String?

        ///
        open var title: String?

        ///
        init() {

        }

        ///
        required public init?(map: Map) {

        }

        ///
        open func mapping(map: Map) {
            value <- map["value"]
            title <- map["title"]
        }
    }

    ///
    open class ClassifiedResultItem: ResultItem {

        ///
        open var classification: Int?

        ///
        override open func mapping(map: Map) {
            super.mapping(map: map)

            classification <- map["classification"]
        }
    }
}
