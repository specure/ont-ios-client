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
    defaultDateFormatter.locale = NSLocale.current
    defaultDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    if let date = $0 {
        return defaultDateFormatter.date(from: date)
    }
    else {
        return Date()
    }
}, toJSON: {
    let defaultDateFormatter = DateFormatter()
    defaultDateFormatter.locale = NSLocale.current
    defaultDateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    if let date = $0 {
        return defaultDateFormatter.string(from: date)
    }
    else {
        return ""
    }
})
