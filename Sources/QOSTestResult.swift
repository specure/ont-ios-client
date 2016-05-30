//
//  QOSTestResult.swift
//  RMBT
//
//  Created by Benjamin Pucher on 09.12.14.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

import Foundation

///
class QOSTestResult {

    ///
    var resultDictionary = QOSTestResults()

    ///
    var testType: QOSTestType

    ///
    var fatalError = false

    ///
    var readOnly = false

    //

    ///
    init(type: QOSTestType) {
        self.testType = type

        resultDictionary["test_type"] = type.rawValue
    }

    ///
    func isEmpty() -> Bool {
        return !fatalError && resultDictionary.isEmpty
    }

    ///
    func freeze() {
        readOnly = true
    }

}

// MARK: Printable methods

///
extension QOSTestResult: CustomStringConvertible {

    ///
    var description: String {
        return "QOSTestResult: type: \(testType.rawValue), fatalError: \(fatalError), resultDictionary: \(resultDictionary)"
    }
}

// MARK: Custom set methods

///
extension QOSTestResult {

    ///
    func set(key: String, value: AnyObject?) {
        if !readOnly {
            resultDictionary[key] = jsonValueOrNull(value)
        }
    }

    // TODO: can this be improved?

    ///
    func set(key: String, number: UInt!) {
        set(key, value: (number != nil ? NSNumber(unsignedLong: number) : nil))
    }

    ///
    func set(key: String, number: UInt8!) {
        set(key, value: (number != nil ? NSNumber(unsignedChar: number) : nil))
    }

    ///
    func set(key: String, number: UInt16!) {
        set(key, value: (number != nil ? NSNumber(unsignedShort: number) : nil))
    }

    ///
    func set(key: String, number: UInt32!) {
        set(key, value: (number != nil ? NSNumber(unsignedInt: number) : nil))
    }

    ///
    func set(key: String, number: UInt64!) {
        set(key, value: (number != nil ? NSNumber(unsignedLongLong: number) : nil))
    }

    ///
    func set(key: String, number: Int!) {
        set(key, value: (number != nil ? NSNumber(long: number) : nil))
    }

    ///
    func set(key: String, number: Int8!) {
        set(key, value: (number != nil ? NSNumber(char: number) : nil))
    }

    ///
    func set(key: String, number: Int16!) {
        set(key, value: (number != nil ? NSNumber(short: number) : nil))
    }

    ///
    func set(key: String, number: Int32!) {
        set(key, value: (number != nil ? NSNumber(int: number) : nil))
    }

    ///
    func set(key: String, number: Int64!) {
        set(key, value: (number != nil ? NSNumber(longLong: number) : nil))
    }

}
