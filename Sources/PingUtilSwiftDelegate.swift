//
//  PingUtilSwiftDelegate.swift
//  RMBT
//
//  Created by Benjamin Pucher on 09.02.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
protocol PingUtilSwiftDelegate {

    ///
    func pingUtil(pingUtil: PingUtil, didFailWithError error: NSError!)

    ///
    func pingUtil(pingUtil: PingUtil, didStartWithAddress address: NSData)

    ///
    func pingUtil(pingUtil: PingUtil, didSendPacket packet: NSData)

    ///
    func pingUtil(pingUtil: PingUtil, didReceivePingResponsePacket packet: NSData, withType type: UInt8, fromIp: String)
}
