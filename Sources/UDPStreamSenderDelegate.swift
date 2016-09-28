/*****************************************************************************************************
 * Copyright 2014-2016 SPECURE GmbH
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *****************************************************************************************************/

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
