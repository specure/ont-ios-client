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
import CocoaAsyncSocket
import RMBTClientPrivate

///
public struct IPInfo: CustomStringConvertible {

    ///
    public var connectionAvailable = false

    ///
    public var nat: Bool {
        return internalIp != externalIp
    }

    ///
    public var internalIp: String? = nil

    ///
    public var externalIp: String? = nil

    ///
    public var description: String {
        return "IPInfo: connectionAvailable: \(connectionAvailable), nat: \(nat), internalIp: \(internalIp), externalIp: \(externalIp)"
    }
}

///
public struct ConnectivityInfo: CustomStringConvertible {

    ///
    public var ipv4 = IPInfo()

    ///
    public var ipv6 = IPInfo()

    ///
    public var description: String {
        return "ConnectivityInfo: ipv4: \(ipv4), ipv6: \(ipv6)"
    }
}

///
public class ConnectivityService: NSObject { // TODO: rewrite with ControlServerNew

    public typealias ConnectivityInfoCallback = (connectivityInfo: ConnectivityInfo) -> ()

    //

    ///
    //let manager: AFHTTPRequestOperationManager

    ///
    var callback: ConnectivityInfoCallback?

    ///
    var connectivityInfo: ConnectivityInfo!

    ///
    var ipv4Finished = false

    ///
    var ipv6Finished = false

    ///
    public override init() { // TODO: USE ALAMOFIRE -> use control server class for this!!
        /*manager = AFHTTPRequestOperationManager(baseURL: NSURL(string: ControlServerNew.sharedControlServer.baseUrl))

        manager.requestSerializer = AFJSONRequestSerializer()
        manager.responseSerializer = AFJSONResponseSerializer()

        manager.requestSerializer.timeoutInterval = 5 // 5 sec
        manager.requestSerializer.cachePolicy = .ReloadIgnoringLocalAndRemoteCacheData*/
    }

    ///
    public func checkConnectivity(callback: ConnectivityInfoCallback) {
        if self.callback != nil { // don't allow multiple concurrent executions
            return
        }

        self.callback = callback
        self.connectivityInfo = ConnectivityInfo()

        getLocalIpAddressesFromSocket()

        ipv4Finished = false
        ipv6Finished = false

        checkIPV4()
        checkIPV6()
    }

    ///
    private func checkIPV4() { // TODO: rewrite with ControlServerNew
        /*let ipv4Url = ControlServer.sharedControlServer.ipv4RequestUrl

        var infoParams = ControlServer.sharedControlServer.systemInfoParams()
        infoParams["uuid"] = ControlServer.sharedControlServer.uuid

        // TODO: move this request to control server class
        manager.POST(ipv4Url, parameters: infoParams, success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in

            logger.debug("\(responseObject)")

            if operation.response.statusCode == 200 {

                let ip = responseObject["ip"]
                let v = responseObject["v"]

                logger.debug("IP: \(ip), version: \(v)")

                self.connectivityInfo.ipv4.connectionAvailable = true
                self.connectivityInfo.ipv4.externalIp = (ip as? String)
            } else {
                // TODO: ?
            }

            self.ipv4Finished = true
            self.callCallback()

        }) { (operation: AFHTTPRequestOperation?, error: NSError!) in
            // logger.debug("ERROR \(error?)")
            logger.debug("ipv4 request ERROR")

            self.connectivityInfo.ipv4.connectionAvailable = false

            self.ipv4Finished = true
            self.callCallback()
        }*/
    }

    ///
    private func checkIPV6() { // TODO: rewrite with ControlServerNew
        /*let ipv6Url = ControlServer.sharedControlServer.ipv6RequestUrl

        var infoParams = ControlServer.sharedControlServer.systemInfoParams()
        infoParams["uuid"] = ControlServer.sharedControlServer.uuid

        // TODO: move this request to control server class
        manager.POST(ipv6Url, parameters: infoParams, success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) -> Void in

            if operation.response.statusCode == 200 {
                let ip = responseObject["ip"]
                let v = responseObject["v"]

                if ("\(ip)" as NSString).isValidIPv6() {
                    logger.debug("IPv6: \(ip), version: \(v)")

                    self.connectivityInfo.ipv6.connectionAvailable = true
                    self.connectivityInfo.ipv6.externalIp = (ip as? String)
                } else {
                    logger.debug("IPv6: \(ip), version: \(v), NOT VALID")
                }

            } else {
                // TODO: ?
            }

            self.ipv6Finished = true
            self.callCallback()

        }) { (operation: AFHTTPRequestOperation!, error: NSError!) -> Void in
            // logger.debug("ERROR \(error?)")
            logger.debug("ipv6 request ERROR")

            self.connectivityInfo.ipv6.connectionAvailable = false

            self.ipv6Finished = true
            self.callCallback()
        }*/
    }

    ///
    private func callCallback() {
        objc_sync_enter(self)

        if !(ipv4Finished && ipv6Finished) {
            objc_sync_exit(self)
            return
        }

        objc_sync_exit(self)

        let savedCallback = callback
        callback = nil

        savedCallback?(connectivityInfo: connectivityInfo)
    }

}

// MARK: IP addresses

///
extension ConnectivityService {

    ///
    private func getLocalIpAddresses() { // see: http://stackoverflow.com/questions/25626117/how-to-get-ip-address-in-swift
        // Get list of all interfaces on the local machine:
        var ifaddr: UnsafeMutablePointer<ifaddrs> = nil
        if getifaddrs(&ifaddr) == 0 {

            // For each interface ...
            var ptr = ifaddr
            while ptr != nil {
            // for (var ptr = ifaddr; ptr != nil; ptr = ptr.memory.ifa_next) {
                let flags = Int32(ptr.memory.ifa_flags)
                var addr = ptr.memory.ifa_addr.memory

                // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
                if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                    if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {

                        // Convert interface address to a human readable string:
                        var hostname = [CChar](count: Int(NI_MAXHOST), repeatedValue: 0)
                        if getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                            if let address = String.fromCString(hostname) {

                                if addr.sa_family == UInt8(AF_INET) {
                                    if self.connectivityInfo.ipv4.internalIp == nil {
                                        self.connectivityInfo.ipv4.internalIp = address
                                        logger.debug("local ipv4 address from getifaddrs: \(address)")
                                    }
                                } else if addr.sa_family == UInt8(AF_INET6) {
                                    if self.connectivityInfo.ipv6.internalIp == nil {
                                        self.connectivityInfo.ipv6.internalIp = address
                                        logger.debug("local ipv6 address from getifaddrs: \(address)")
                                    }
                                }
                            }
                        }
                    }
                }

                ptr = ptr.memory.ifa_next
            }
            freeifaddrs(ifaddr)
        }
    }

    ///
    private func getLocalIpAddressesFromSocket() {
        let udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0))

        let host = NSURL(string: RMBT_URL_HOST)?.host ?? "specure.com"

        // connect to any host
        do {
            try udpSocket.connectToHost(host, onPort: 11111) // TODO: which host, which port? // try!
        } catch {
            getLocalIpAddresses() // fallback
        }
    }

}

// MARK: GCDAsyncUdpSocketDelegate

///
extension ConnectivityService: GCDAsyncUdpSocketDelegate {

    ///
    public func udpSocket(sock: GCDAsyncUdpSocket, didConnectToAddress address: NSData) {
        connectivityInfo.ipv4.internalIp = sock.localHost_IPv4()
        connectivityInfo.ipv6.internalIp = sock.localHost_IPv6()

        logger.debug("local ipv4 address from socket: \(self.connectivityInfo.ipv4.internalIp)")
        logger.debug("local ipv6 address from socket: \(self.connectivityInfo.ipv6.internalIp)")

        sock.close()
    }

    ///
    public func udpSocket(sock: GCDAsyncUdpSocket, didNotConnect error: NSError?) {
        logger.debug("didNotConnect: \(error)")

        getLocalIpAddresses() // fallback
    }

    ///
    public func udpSocketDidClose(sock: GCDAsyncUdpSocket, withError error: NSError?) {
        logger.debug("udpSocketDidClose: \(error)")

        getLocalIpAddresses() // fallback
    }

}
