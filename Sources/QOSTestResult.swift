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
open class QOSTestResult: NSObject {

    ///
    open var resultDictionary = QOSTestResults()

    ///
    open var testType: QosMeasurementType

    ///
    open var fatalError = false

    ///
    open var readOnly = false

    //

    ///
    public init(type: QosMeasurementType) {
        self.testType = type

        resultDictionary["test_type"] = type.rawValue as Any?
    }

    ///
    open func isEmpty() -> Bool {
        return !fatalError && resultDictionary.isEmpty
    }

    ///
    open func freeze() {
        readOnly = true
    }

}

// MARK: Printable methods

///
extension QOSTestResult {

    ///
    open override var description: String {
        return "QOSTestResult: type: \(testType.rawValue), fatalError: \(fatalError), resultDictionary: \(resultDictionary)"
    }
}

// MARK: Custom set methods

///
extension QOSTestResult {

    ///
    public func set(_ key: String, value: Any?) {
        if !readOnly {
            resultDictionary[key] = jsonValueOrNull(value as Any?)
        }
    }

    // TODO: can this be improved?

    ///
    public func set(_ key: String, number: UInt!) {
        set(key, value: (number != nil ? NSNumber(value: number as UInt) : nil))
    }

    ///
    public func set(_ key: String, number: UInt8!) {
        set(key, value: (number != nil ? NSNumber(value: number as UInt8) : nil))
    }

    ///
    public func set(_ key: String, number: UInt16!) {
        set(key, value: (number != nil ? NSNumber(value: number as UInt16) : nil))
    }

    ///
    public func set(_ key: String, number: UInt32!) {
        set(key, value: (number != nil ? NSNumber(value: number as UInt32) : nil))
    }

    ///
    public func set(_ key: String, number: UInt64!) {
        set(key, value: (number != nil ? NSNumber(value: number as UInt64) : nil))
    }

    ///
    public func set(_ key: String, number: Int!) {
        set(key, value: (number != nil ? NSNumber(value: number as Int) : nil))
    }

    ///
    public func set(_ key: String, number: Int8!) {
        set(key, value: (number != nil ? NSNumber(value: number as Int8) : nil))
    }

    ///
    public func set(_ key: String, number: Int16!) {
        set(key, value: (number != nil ? NSNumber(value: number as Int16) : nil))
    }

    ///
    public func set(_ key: String, number: Int32!) {
        set(key, value: (number != nil ? NSNumber(value: number as Int32) : nil))
    }

    ///
    public func set(_ key: String, number: Int64!) {
        set(key, value: (number != nil ? NSNumber(value: number as Int64) : nil))
    }

}
