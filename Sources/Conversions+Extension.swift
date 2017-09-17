//
//  Conversions+Extension.swift
//  rmbt-ios-client
//
//  Created by Tomas Baculák on 10/11/2016.
//
//

import Foundation


extension Double {
    /// Rounds the double to decimal places value
    func roundToPlaces(_ places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return ((self * divisor) / divisor).rounded()
    }
}
