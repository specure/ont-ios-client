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
let UInt64NSNumberTransformOf = TransformOf<UInt64, NSNumber>(fromJSON: { $0?.uint64Value }, toJSON: { $0.map { NSNumber(value: $0) } })

let DateStringTransformOf = TransformOf<Date, String>(fromJSON: {
    let defaultDateFormatter = DateFormatter()
//    defaultDateFormatter.locale = NSLocale.current
    defaultDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    if let date = $0 {
        return defaultDateFormatter.date(from: date)
    }
    else {
        return Date()
    }
}, toJSON: {
    let defaultDateFormatter = DateFormatter()
//    defaultDateFormatter.locale = NSLocale.current
    defaultDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    if let date = $0 {
        return defaultDateFormatter.string(from: date)
    }
    else {
        return ""
    }
})

let IntDateStringTransformOf = TransformOf<Int, String>(fromJSON: {
    let defaultDateFormatter = DateFormatter()
    defaultDateFormatter.locale = Locale(identifier: "en_US_POSIX")
    defaultDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    if let date = $0 {
        return Int(defaultDateFormatter.date(from: date)?.timeIntervalSince1970 ?? 0.0)
    }
    else {
        return Int(Date().timeIntervalSince1970)
    }
}, toJSON: {
    let defaultDateFormatter = DateFormatter()
    defaultDateFormatter.locale = Locale(identifier: "en_US_POSIX")
    defaultDateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    if let timestamp = $0 {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        return defaultDateFormatter.string(from: date)
    }
    else {
        return ""
    }
})
