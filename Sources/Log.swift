//
//  Log.swift
//  RMBTClient
//
//  Created by Sergey Glushchenko on 4/4/18.
//

import UIKit
import XCGLogger

class Log: NSObject {
    static let logger = XCGLogger.init(identifier: "RMBTClient", includeDefaultDestinations: true)
}
