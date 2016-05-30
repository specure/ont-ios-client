//
//  RMBTThroughput.swift
//  RMBT
//
//  Created by Benjamin Pucher on 29.03.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
class RMBTThroughput: CustomStringConvertible {

    ///
    var length: UInt64

    ///
    private var _startNanos: UInt64 // nasty hack to get around endless loop with didSet
    var startNanos: UInt64 {
        get {
            return _startNanos
        }
        set {
            _startNanos = newValue
            _durationNanos = _endNanos - _startNanos

            assert(_durationNanos >= 0, "Invalid duration")
        }
    }

    ///
    private var _endNanos: UInt64 // nasty hack to get around endless loop with didSet
    var endNanos: UInt64 {
        get {
            return _endNanos
        }
        set {
            _endNanos = newValue
            _durationNanos = _endNanos - _startNanos

            assert(_durationNanos >= 0, "Invalid duration")
        }
    }

    ///
    private var _durationNanos: UInt64 // nasty hack to get around endless loop with didSet
    var durationNanos: UInt64 {
        get {
            return _durationNanos
        }
        set {
            _durationNanos = newValue
            _endNanos = _startNanos + _durationNanos

            assert(_durationNanos >= 0, "Invalid duration")
        }
    }

    //

    convenience init() {
        self.init(length: 0, startNanos: 0, endNanos: 0)
    }

    ///
    init(length: UInt64, startNanos: UInt64, endNanos: UInt64) {
        self.length = length
        self._startNanos = startNanos
        self._endNanos = endNanos

        self._durationNanos = endNanos - startNanos

        assert(_durationNanos >= 0, "Invalid duration")
    }

    ///
    func containsNanos(nanos: UInt64) -> Bool {
        return (_startNanos <= nanos && _endNanos >= nanos)
    }

    ///
    func kilobitsPerSecond() -> UInt32 {
        return UInt32(Double(length) * 8.0 / (Double(_durationNanos) * Double(1e-6))) // TODO: improve
    }

    ///
    var description: String {
        return String(format: "(%@-%@, %lld bytes, %@)",
                        RMBTSecondsStringWithNanos(_startNanos),
                        RMBTSecondsStringWithNanos(_endNanos),
                        length,
                        RMBTSpeedMbpsString(kilobitsPerSecond()))
    }
}
