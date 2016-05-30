//
//  UDPStreamReceiverDelegate.swift
//  RMBT
//
//  Created by Benjamin Pucher on 25.02.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
protocol UDPStreamReceiverDelegate {

    /// returns false if the class should stop
    func udpStreamReceiver(udpStreamReceiver: UDPStreamReceiver, didReceivePacket packetData: NSData) -> Bool

    /// returns true if the class should send response packet
    func udpStreamReceiver(udpStreamReceiver: UDPStreamReceiver, willSendPacketWithNumber packetNumber: UInt16, inout data: NSMutableData) -> Bool
}
