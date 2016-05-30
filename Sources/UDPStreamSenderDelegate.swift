//
//  UDPStreamSenderDelegate.swift
//  RMBT
//
//  Created by Benjamin Pucher on 27.02.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
protocol UDPStreamSenderDelegate {

    /// returns false if the class should stop
    func udpStreamSender(udpStreamSender: UDPStreamSender, didReceivePacket packetData: NSData) -> Bool

    /// returns false if the class should stop
    func udpStreamSender(udpStreamSender: UDPStreamSender, willSendPacketWithNumber packetNumber: UInt16, inout data: NSMutableData) -> Bool

    /// returns the port on which the socket has bound
    func udpStreamSender(udpStreamSender: UDPStreamSender, didBindToPort port: UInt16)
}
