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
#if swift(>=3.2)
    import Darwin
#else
    import RMBTClientPrivate
#endif

import Foundation


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
        return "IPInfo: connectionAvailable: \(connectionAvailable), nat: \(nat), internalIp: \(String(describing: internalIp)), externalIp: \(String(describing: externalIp))"
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
open class ConnectivityService: NSObject { // TODO: rewrite with ControlServerNew

    public typealias ConnectivityInfoCallback = (_ connectivityInfo: ConnectivityInfo) -> ()

    ///
    var callback: ConnectivityInfoCallback?

    ///
    var connectivityInfo: ConnectivityInfo!

    ///
    var ipv4Finished = false

    ///
    var ipv6Finished = false

    ///
    open func checkConnectivity(_ callback: @escaping ConnectivityInfoCallback) {
        if self.callback != nil { // don't allow multiple concurrent executions
            return
        }

        self.callback = callback
        self.connectivityInfo = ConnectivityInfo()

        getLocalIpAddresses()
        getLocalIpAddressesFromSocket()

        checkIPV4()
        checkIPV6()
    }

    ///
    private func checkIPV4() {
        
        self.ipv4Finished = false
        
        ControlServer.sharedControlServer.getIpv4( success: { response in
            
            self.connectivityInfo.ipv4.connectionAvailable = true
            self.connectivityInfo.ipv4.externalIp = response.ip
            
            self.finishIPv4Check()
            
        }, error: { error in
            self.connectivityInfo.ipv4.connectionAvailable = false
            
            self.finishIPv4Check()
        })
    }
    
    private func finishIPv4Check() {
        self.ipv4Finished = true
        self.callCallback()
    }

    ///
    private func checkIPV6() {
        
        self.connectivityInfo?.ipv6.connectionAvailable = (self.connectivityInfo?.ipv6.internalIp != nil)
        
        self.ipv6Finished = true
        self.callCallback()
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

        savedCallback?(connectivityInfo)
    }

}

// MARK: IP addresses

///
extension ConnectivityService {

    ///
    fileprivate func getLocalIpAddresses() { // see: http://stackoverflow.com/questions/25626117/how-to-get-ip-address-in-swift
        // Get list of all interfaces on the local machine:
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {

            // For each interface ...
            var ptr = ifaddr
            while ptr != nil {
            // for (var ptr = ifaddr; ptr != nil; ptr = ptr.memory.ifa_next) {
                let flags = Int32((ptr?.pointee.ifa_flags)!)
                var addr = ptr?.pointee.ifa_addr.pointee

                // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
                if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                    if addr?.sa_family == UInt8(AF_INET) || addr?.sa_family == UInt8(AF_INET6) {

                        // Convert interface address to a human readable string:
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        if getnameinfo(&addr!, socklen_t((addr?.sa_len)!), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                            if let address = String(validatingUTF8: hostname) {

                                if addr?.sa_family == UInt8(AF_INET) {
                                    if self.connectivityInfo.ipv4.internalIp != address {
                                        self.connectivityInfo.ipv4.internalIp = address
                                        logger.debug("local ipv4 address from getifaddrs: \(address)")
                                    }
                                }
                                if addr?.sa_family == UInt8(AF_INET6) {
                                    if self.connectivityInfo.ipv6.internalIp != address {
                                        self.connectivityInfo.ipv6.internalIp = address
                                        self.connectivityInfo.ipv6.externalIp = address
                                        logger.debug("local ipv6 address from getifaddrs: \(address)")
                                    }
                                }
                            }
                        }
                    }
                }

                ptr = ptr?.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }
    }

    ///
    fileprivate func getLocalIpAddressesFromSocket() {
        let udpSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: DispatchQueue.global(qos: .default))

        if RMBTSettings.sharedSettings.nerdModeForceIPv4 {
            udpSocket.setIPv6Enabled(false)
            udpSocket.setPreferIPv4()
        }
        if RMBTSettings.sharedSettings.nerdModeForceIPv6 {
            udpSocket.setIPv4Enabled(false)
            udpSocket.setPreferIPv6()
        }
        if !RMBTSettings.sharedSettings.nerdModeForceIPv4 && !RMBTSettings.sharedSettings.nerdModeForceIPv6 {
            udpSocket.setIPv6Enabled(true)
            udpSocket.setPreferIPv6()
        }
        
        logger.debug("get local address from socket is prefered IPv4:\(udpSocket.isIPv4Preferred()), prefered IPv6:\(udpSocket.isIPv6Preferred()), enabled IPv4:\(udpSocket.isIPv4Enabled()), enabled IPv6: \(udpSocket.isIPv6Enabled())")
        let host = URL(string: RMBT_URL_HOST)?.host ?? "specure.com"

        // connect to any host
        do {
            try udpSocket.connect(toHost: host, onPort: 11111) // TODO: which host, which port? // try!
        } catch {
            getLocalIpAddresses() // fallback
        }
    }

}

// MARK: GCDAsyncUdpSocketDelegate

///
extension ConnectivityService: GCDAsyncUdpSocketDelegate {

    ///
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        if let ip = sock.localHost_IPv4() {
            connectivityInfo.ipv4.internalIp = ip
        }
        if let ip = sock.localHost_IPv6() {
            connectivityInfo.ipv6.internalIp = ip
            connectivityInfo.ipv6.externalIp = ip
        }

        logger.debug("local ipv4 address from socket: \(String(describing: self.connectivityInfo.ipv4.internalIp))")
        logger.debug("local ipv6 address from socket: \(String(describing: self.connectivityInfo.ipv6.internalIp))")

        sock.close()
    }

    ///
    @nonobjc public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: NSError?) {
        logger.debug("didNotConnect: \(String(describing: error))")

        getLocalIpAddresses() // fallback
    }

    ///
    @nonobjc public func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: NSError?) {
        logger.debug("udpSocketDidClose: \(String(describing: error))")

        getLocalIpAddresses() // fallback
    }

}
