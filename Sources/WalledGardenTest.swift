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
public class WalledGardenTest {

    ///
    public typealias WalledGardenResultCallback = (isWalledGarden: Bool) -> ()

    ///
    public class func isWalledGardenConnection(callback: WalledGardenResultCallback) {
        if let url = NSURL(string: WALLED_GARDEN_URL) {

            let request = NSMutableURLRequest(URL: url)

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
