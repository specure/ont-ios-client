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
extension String {

    ///
    public func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    ///
    public func stringByRemovingAllNewlines() -> String {
        return self.replacingOccurrences(of: "\n", with: "", options: .literal, range: nil)
    }

    ///
    public func stringByRemovingLastNewline() -> String { // TODO: improve...
        return self.replacingOccurrences(of: "\n", with: "", options: .backwards, range: self.index(self.endIndex, offsetBy: -2)..<self.endIndex)
    }
    
    // add ms
    public mutating func addMsString() -> String { return self + " ms"}
    
    // %
    public mutating func addPercentageString() -> String { return self + " %"}
    
    // add Mbps
    public mutating func addMbpsString() -> String { return self + " " + "Mbps"}

}
