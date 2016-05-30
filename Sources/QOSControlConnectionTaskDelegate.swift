//
//  QOSControlConnectionTaskDelegate.swift
//  RMBT
//
//  Created by Benjamin Pucher on 09.12.14.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

import Foundation

///
protocol QOSControlConnectionTaskDelegate {

    ///
    func controlConnection(connection: QOSControlConnection, didReceiveTaskResponse response: String, withTaskId taskId: UInt, tag: Int)

    ///
    func controlConnection(connection: QOSControlConnection, didReceiveTimeout elapsed: NSTimeInterval, withTaskId taskId: UInt, tag: Int)
}
