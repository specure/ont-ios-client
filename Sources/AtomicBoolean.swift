//
//  AtomicBoolean.swift
//  RMBT
//
//  Created by Benjamin Pucher on 25.02.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
public class AtomicBoolean {

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
    func testAndSet(newValue: Bool) -> Bool {
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
    public func get() -> Bool {
        return value != 0
    }

    ///
    public func set(newValue: Bool) {
        value = newValue ? 1 : 0
    }

}

///
extension AtomicBoolean: BooleanLiteralConvertible {

}

///
extension AtomicBoolean: BooleanType {

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
