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
open class AtomicBoolean {

    ///
    private var value: UInt8 = 0

    ///
    public init() {

    }

    ///
    public required init(booleanLiteral initialValue: Bool) {
        set(initialValue)
    }

    ///
    func testAndSet(_ newValue: Bool) -> Bool {
        if newValue {
            return OSAtomicTestAndSet(7, &value)
        } else {
            return OSAtomicTestAndClear(7, &value)
        }
    }

    ///
    func test() -> Bool {
        return value != 0
    }

    ///
    open func get() -> Bool {
        return value != 0
    }

    ///
    open func set(_ newValue: Bool) {
        value = newValue ? 1 : 0
    }

}

///
extension AtomicBoolean: ExpressibleByBooleanLiteral {

}

///
extension AtomicBoolean {

    ///
    public var boolValue: Bool {
        return get()
    }
}

///
extension AtomicBoolean: CustomStringConvertible {

    ///
    public var description: String {
        return "\(get())"
    }
}
