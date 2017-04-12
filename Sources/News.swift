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
public final class News {

    ///
    public let title: String

    ///
    public let text: String

    ///
    public let uid: UInt

    ///
    public init(response: [String: AnyObject]) {
        self.title = response["title"] as! String
        self.text = response["text"] as! String
        self.uid = (response["uid"] as! NSNumber).uintValue
    } // TODO: does this work? casts to NSString and CLong?
}
