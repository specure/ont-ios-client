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
public class QOSTestResult {

    ///
    public var resultDictionary = QOSTestResults()

    ///
    public var testType: QOSMeasurementType

    ///
    public var fatalError = false

    ///
    public var readOnly = false

    //

    ///
    public init(type: QOSMeasurementType) {
        self.testType = type

        resultDictionary["test_type"] = type.rawValue
    }

    ///
    public func isEmpty() -> Bool {
        return !fatalError && resultDictionary.isEmpty
    }

    ///
    public func freeze() {
        readOnly = true
    }

}

// MARK: Printable methods

///
extension QOSTestResult: CustomStringConvertible {

    ///
    public var description: String {
        return "QOSTestResult: type: \(testType.rawValue), fatalError: \(fatalError), resultDictionary: \(resultDictionary)"
    }
}

// MARK: Custom set methods

///
extension QOSTestResult {

    ///
    public func set(key: String, value: AnyObject?) {
        if !readOnly {
            resultDictionary[key] = jsonValueOrNull(value)
        }
    }

    // TODO: can this be improved?

    ///
    public func set(key: String, number: UInt!) {
        set(key, value: (number != nil ? NSNumber(unsignedLong: number) : nil))
    }

    ///
    public func set(key: String, number: UInt8!) {
        set(key, value: (number != nil ? NSNumber(unsignedChar: number) : nil))
    }

    ///
    public func set(key: String, number: UInt16!) {
        set(key, value: (number != nil ? NSNumber(unsignedShort: number) : nil))
    }

    ///
    public func set(key: String, number: UInt32!) {
        set(key, value: (number != nil ? NSNumber(unsignedInt: number) : nil))
    }

    ///
    public func set(key: String, number: UInt64!) {
        set(key, value: (number != nil ? NSNumber(unsignedLongLong: number) : nil))
    }

    ///
    public func set(key: String, number: Int!) {
        set(key, value: (number != nil ? NSNumber(long: number) : nil))
    }

    ///
    public func set(key: String, number: Int8!) {
        set(key, value: (number != nil ? NSNumber(char: number) : nil))
    }

    ///
    public func set(key: String, number: Int16!) {
        set(key, value: (number != nil ? NSNumber(short: number) : nil))
    }

    ///
    public func set(key: String, number: Int32!) {
        set(key, value: (number != nil ? NSNumber(int: number) : nil))
    }

    ///
    public func set(key: String, number: Int64!) {
        set(key, value: (number != nil ? NSNumber(longLong: number) : nil))
    }

}
