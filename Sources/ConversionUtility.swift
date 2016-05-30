//
//  ConversionUtility.swift
//  RMBT
//
//  Created by Benjamin Pucher on 12.02.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
func nsToSec(ns: UInt64) -> Double {
    return Double(ns / NSEC_PER_SEC)
}

///
func nsToMs(ns: UInt64) -> Double {
    return Double(ns / NSEC_PER_MSEC)
}
