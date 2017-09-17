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

import Foundation

///
struct DNSHeader: CustomStringConvertible {
    var id: UInt16
    var flags: UInt16
    var qdCount: UInt16
    var anCount: UInt16
    var nsCount: UInt16
    var arCount: UInt16

    var description: String {
        return "DNSHeader: [id: \(id), flags: \(flags), qdCount: \(qdCount), anCount: \(anCount), nsCount: \(nsCount), arCount: \(arCount)]"
    }

    init() {
        id = 0
        flags = 0
        qdCount = 0
        anCount = 0
        nsCount = 0
        arCount = 0
    }
}
