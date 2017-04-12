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
class ExtendedTestStat: Mappable {

    ///
    var cpuUsage = TestStat()

    ///
    var memUsage = TestStat()

    ///
    init() {

    }

    ///
    required init?(map: Map) {

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
        required init?(map: Map) {

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
            required init?(map: Map) {

            }

            ///
            func mapping(map: Map) {
                timeNs <- (map["time_ns"], UInt64NSNumberTransformOf)
                value <- map["value"]
            }
        }
    }
}
