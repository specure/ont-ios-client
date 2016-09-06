//
//  ExtendedTestStat.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 23.08.16.
//
//

import Foundation
import ObjectMapper

///
class ExtendedTestStat: Mappable {

    ///
    var cpuUsage = TestStat()

    ///
    var memUsage = TestStat()

    ///
    init() {

    }

    ///
    required init?(_ map: Map) {

    }

    ///
    func mapping(map: Map) {
        cpuUsage <- map["cpu_usage"]
        memUsage <- map["mem_usage"]
    }

    ///
    class TestStat: Mappable {

        ///
        var values = [TestStatValue]()

        ///
        var flags = [[String: AnyObject]]()

        ///
        init() {

        }

        ///
        required init?(_ map: Map) {

        }

        ///
        func mapping(map: Map) {
            values <- map["values"]
            flags <- map["flags"]
        }

        ///
        class TestStatValue: Mappable {

            ///
            var timeNs: UInt64?

            ///
            var value: Double?

            ///
            init() {

            }

            ///
            required init?(_ map: Map) {

            }

            ///
            func mapping(map: Map) {
                timeNs <- (map["time_ns"], UInt64NSNumberTransformOf)
                value <- map["value"]
            }
        }
    }
}
