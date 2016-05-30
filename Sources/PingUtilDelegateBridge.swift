//
//  PingUtilDelegateBridge.swift
//  RMBT
//
//  Created by Benjamin Pucher on 09.02.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
class PingUtilDelegateBridge: NSObject, PingUtilDelegate {

    ///
    let dObj: PingUtilSwiftDelegate

    ///
    init(obj: PingUtilSwiftDelegate) {
        self.dObj = obj
    }

    ///
    func pingUtil(pingUtil: PingUtil, didFailWithError error: NSError?) {
        dObj.pingUtil(pingUtil, didFailWithError: error)
    }

    ///
    func pingUtil(pingUtil: PingUtil, didStartWithAddress address: NSData) {
        dObj.pingUtil(pingUtil, didStartWithAddress: address)
    }

    ///
    func pingUtil(pingUtil: PingUtil, didSendPacket packet: NSData) {
        dObj.pingUtil(pingUtil, didSendPacket: packet)
    }

    ///
    func pingUtil(pingUtil: PingUtil, didReceivePingResponsePacket packet: NSData, withType type: UInt8, fromIp: String) {
        dObj.pingUtil(pingUtil, didReceivePingResponsePacket: packet, withType: type, fromIp: fromIp)
    }

}
