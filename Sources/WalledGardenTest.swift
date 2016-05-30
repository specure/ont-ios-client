//
//  WalledGardenTest.swift
//  RMBT
//
//  Created by Benjamin Pucher on 29.01.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
class WalledGardenTest {

    ///
    typealias WalledGardenResultCallback = (isWalledGarden: Bool) -> ()

    ///
    class func isWalledGardenConnection(callback: WalledGardenResultCallback) {
        if let url: NSURL = NSURL(string: WALLED_GARDEN_URL) {

            let request: NSMutableURLRequest = NSMutableURLRequest(URL: url)

            request.HTTPMethod = "GET"
            request.timeoutInterval = (WALLED_GARDEN_SOCKET_TIMEOUT_MS / 1_000.0)
            request.cachePolicy = .ReloadIgnoringLocalCacheData // disable cache

            // send async request // TODO: or send sync request?
            NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue(), completionHandler: { (response: NSURLResponse?, data: NSData?, error: NSError?) -> Void in
                if let res = response as? NSHTTPURLResponse {
                    let httpResponse = res

                    callback(isWalledGarden: (httpResponse.statusCode != 204))
                } else {
                    callback(isWalledGarden: false) // request failed (probably due to no network connection)
                }
            })
        }
    }

}
