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
class PingUtilDelegateBridge: NSObject, PingUtilDelegate {

    ///
    let dObj: PingUtilSwiftDelegate

    ///
    init(obj: PingUtilSwiftDelegate) {
        self.dObj = obj
    }

    ///
    func pingUtil(_ pingUtil: PingUtil, didFailWithError error: Error?) {
        dObj.pingUtil(pingUtil, didFailWithError: error)
    }

    ///
    func pingUtil(_ pingUtil: PingUtil, didStartWithAddress address: Data) {
        dObj.pingUtil(pingUtil, didStartWithAddress: address)
    }

    ///
    func pingUtil(_ pingUtil: PingUtil, didSendPacket packet: Data) {
        dObj.pingUtil(pingUtil, didSendPacket: packet)
    }

    ///
    func pingUtil(_ pingUtil: PingUtil, didReceivePingResponsePacket packet: Data, withType type: UInt8, fromIp: String) {
        dObj.pingUtil(pingUtil, didReceivePingResponsePacket: packet, withType: type, fromIp: fromIp)
    }

}
