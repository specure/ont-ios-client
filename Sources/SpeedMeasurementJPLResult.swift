//
//  SpeedMeasurementJPLResult.swift
//  RMBTClient
//
//  Created by Sergey Glushchenko on 3/20/18.
//

import ObjectMapper

class SpeedMeasurementJPLResult: Mappable {
    
    var resultInNumPackets: Int?
    var resultInLongestSeqPackets: Int?
    var resultInShortestSeqPackets: Int?
    var resultInMeanJitter: Int64?
    var resultInMaxJitter: Int64?
    var resultInSeqError: Int?
    var resultInSkew: Int64?
    var resultInMaxDelta: Int64?
    var resultOutSkew: Int64?
    var resultOutMaxDelta: Int64?
    var resultOutSeqError: Int64?
    var resultOutLongestSeqPackets: Int64?
    var resultOutShortestSeqPackets: Int64?
    var resultOutMeanJitter: Int64?
    var resultOutMaxJitter: Int64?
    var resultOutNumPackets: Int64?
    var objectiveBitsPerSample: Int = 8
    var objectivePortIn: Int?
    var objectivePortOut: Int?
    var objectiveDelay: Int64?
    var objectiveTimeoutNS: Int64?
    var objectivePayload: Int = 0
    var objectiveCallDuration: Int64 = 1000000000
    var objectiveSampleRate: Int = 8000
    var testDurationInNS: Int64?
    var startTimeInNS: Int64?
    var testResultStatus: String = "ERROR" // TODO: To enum [OK, TIMEOUT, ERROR]
    var classificationPacketLoss: Int = -1
    var classificationJitter: Int = -1
    var voipResultPacketLoss: String = "-"
    var voipResultJitter: String = "-"
    
    required init?(map: Map) {
        
    }
    
    func mapping(map: Map) {
        resultInNumPackets              <- map["voip_result_in_num_packets"]
        resultInLongestSeqPackets       <- map["voip_result_in_long_seq"]
        resultInShortestSeqPackets      <- map["voip_result_in_short_seq"]
        resultInMeanJitter              <- map["voip_result_in_mean_jitter"]
        resultInMaxJitter               <- map["voip_result_in_max_jitter"]
        resultInSeqError                <- map["voip_result_in_sequence_error"]
        resultInSkew                    <- map["voip_result_in_skew"]
        resultInMaxDelta                <- map["voip_result_in_max_delta"]
        resultOutSkew                   <- map["voip_result_out_skew"]
        resultOutMaxDelta               <- map["voip_result_out_max_delta"]
        resultOutSeqError               <- map["voip_result_out_sequence_error"]
        resultOutLongestSeqPackets      <- map["voip_result_out_long_seq"]
        resultOutShortestSeqPackets     <- map["voip_result_out_short_seq"]
        resultOutMeanJitter             <- map["voip_result_out_mean_jitter"]
        resultOutMaxJitter              <- map["voip_result_out_max_jitter"]
        resultOutNumPackets             <- map["voip_result_out_num_packets"]
        objectiveBitsPerSample          <- map["voip_objective_bits_per_sample"]
        objectivePortIn                 <- map["voip_objective_in_port"]
        objectivePortOut                <- map["voip_objective_out_port"]
        objectiveDelay                  <- map["voip_objective_delay"]
        objectiveTimeoutNS              <- map["voip_objective_timeout"]
        objectivePayload                <- map["voip_objective_payload"]
        objectiveCallDuration           <- map["voip_objective_call_duration"]
        objectiveSampleRate             <- map["voip_objective_sample_rate"]
        testDurationInNS                <- map["duration_ns"]
        startTimeInNS                   <- map["start_time_ns"]
        testResultStatus                <- map["voip_result_status"]
        classificationPacketLoss        <- map["classification_packet_loss"]
        classificationJitter            <- map["classification_jitter"]
        voipResultPacketLoss            <- map["voip_result_packet_loss"]
        voipResultJitter                <- map["voip_result_jitter"]
        
    }
    

}
/*
* `voip_objective_in_port` => the port for the incoming voice stream
* `voip_objective_out_port` => the port for the outgoing voice stream
* `voip_objective_call_duration` => (_optional_) duration of the simulated call, default: 1000000000ns (=1000ms)
* `voip_objective_bits_per_sample` => (_optional_) bits per sample, default: 8
* `voip_objective_sample_rate` => (_optional_) the sample rate in _Hz_, default: 8000
* `voip_result_status` => the test result, enum:
* * `OK` - the test was successful (=test execution; regardless of the test result)
* * `TIMEOUT` - the test timeout has beed reached
* * `ERROR` - another error occured
* incoming voice stream results (client side):
* * `voip_result_in_short_seq` => the shortest correct packet sequence (fewest number of packets in correct order)
* * `voip_result_in_long_seq` => the longest correct packet sequence (most number of packets in correct order)
* * `voip_result_in_max_jitter` => the max jitter in ns
* * `voip_result_in_mean_jitter` => the mean jitter in ns
* * `voip_result_in_skew` => the skew in ns
* * `voip_result_in_num_packets` => number of packets received
* * `voip_result_in_max_delta` => highest delay between received packets
* * `voip_result_in_sequence_error` => number of sequence errors (packets out of order)
* outgoing voice stream results:
* * `voip_result_out_short_seq` => the shortest correct packet sequence (fewest number of packets in correct order)
* * `voip_result_out_long_seq` => the longest correct packet sequence (most number of packets in correct order)
* * `voip_result_out_max_jitter` => the max jitter in ns
* * `voip_result_out_mean_jitter` => the mean jitter in ns
* * `voip_result_out_skew` => the skew in ns
* * `voip_result_out_max_delta` => highest delay between received packets
* * `voip_result_out_num_packets` => number of packets received
* * `voip_result_out_sequence_error` => number of sequence errors (packets out of order)
*/
