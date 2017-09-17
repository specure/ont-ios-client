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

import Foundation

///
public enum RMBTNetworkType: Int {
    case unknown = -1
    case none = 0 // Used internally to denote no connection
    case browser = 98
    case wiFi = 99
    case cellular = 105
}

///
public func RMBTNetworkTypeMake(_ code: Int) -> RMBTNetworkType {
    return RMBTNetworkType(rawValue: code) ?? .unknown
}

///
public func RMBTNetworkTypeIdentifier(_ networkType: RMBTNetworkType) -> String? {
    switch networkType {
        case .cellular: return "cellular"
        case .wiFi:     return "wifi"
        case .browser:  return "browser"
        default:        return nil
    }
}
