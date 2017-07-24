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
open class Ping: Mappable, CustomStringConvertible {

    ///
    var serverNanos: UInt64?

    ///
    var clientNanos: UInt64?

    /// relative to test start
    var relativeTimestampNanos: UInt64?

    //

    ///
    init(serverNanos: UInt64, clientNanos: UInt64, relativeTimestampNanos timestampNanos: UInt64) {
        self.serverNanos = serverNanos
        self.clientNanos = clientNanos
        self.relativeTimestampNanos = timestampNanos
    }

    ///
    required public init?(map: Map) {

    }

    ///
    open func mapping(map: Map) {
        serverNanos             <- (map["value_server"], UInt64NSNumberTransformOf)
        clientNanos             <- (map["value"], UInt64NSNumberTransformOf)
        relativeTimestampNanos  <- (map["relative_time_ns"], UInt64NSNumberTransformOf)
    }

    ///
    open var description: String {
        //return String(format: "RMBTPing (server=%" PRIu64 ", client=%" PRIu64 ")", serverNanos, clientNanos)
        return "RMBTPing  (server = \(String(describing: serverNanos)), client = \(String(describing: clientNanos)))"
    }
}
