//
//  SocketUtils.swift
//  RMBT
//
//  Created by Benjamin Pucher on 09.12.14.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

import Foundation
import CocoaAsyncSocket

/// contains convenience methods for working with sockets
class SocketUtils {

    ///
    class func writeLine(sock: GCDAsyncSocket, line: String, withTimeout timeout: NSTimeInterval, tag: Int) { // TODO: use nano seconds timeouts
        var line = line

        // append \n to command if not already done
        if !line.hasSuffix("\n") {
            line = line + "\n"
        }

        logger.verbose("-- writing line '\(line)'")

        if let lineData = line.dataUsingEncoding(NSUTF8StringEncoding) {
            sock.writeData(lineData, withTimeout: timeout, tag: tag)
        } else {
            // TODO: return false or error?
        }
    }

    ///
    class func readLine(sock: GCDAsyncSocket, tag: Int, withTimeout timeout: NSTimeInterval) {
        if let data = "\n".dataUsingEncoding(QOS_SOCKET_DEFAULT_CHARACTER_ENCODING) {
            sock.readDataToData(data, withTimeout: timeout, tag: tag)
        }
    }

    /// parses NSData object to String using default encoding
    class func parseResponseToString(data: NSData) -> String? {
        if let str = NSString(data: data, encoding: QOS_SOCKET_DEFAULT_CHARACTER_ENCODING) {
            return str as String
        }

        return nil
    }

}
