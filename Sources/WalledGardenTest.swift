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
import Alamofire

///
open class WalledGardenTest {

    ///
    public typealias WalledGardenResultCallback = (_ isWalledGarden: Bool) -> ()

    ///
    open class func isWalledGardenConnection(_ callback: @escaping WalledGardenResultCallback) {
        if let url = URL(string: WALLED_GARDEN_URL) {

            let request = NSMutableURLRequest(url: url)

            request.httpMethod = "GET"
            request.timeoutInterval = (WALLED_GARDEN_SOCKET_TIMEOUT_MS / 1_000.0)
            request.cachePolicy = .reloadIgnoringLocalCacheData // disable cache

// Original solution 
            
            // send async request // TODO: or send sync request?
            AF.request(request as URLRequest).response(queue: .main) { (response) in
                if let res = response.response {
                    let httpResponse = res

                    callback((httpResponse.statusCode == 204))
                } else {
                    callback(false) // request failed (probably due to no network connection)
                }
            }
            
//            var newRequest = URLRequest(url: url)
//            newRequest.httpMethod = "GET"
//            newRequest.timeoutInterval = (WALLED_GARDEN_SOCKET_TIMEOUT_MS / 1_000.0)
//            newRequest.cachePolicy = .reloadIgnoringLocalCacheData // disable cache
            
//            let task = URLSession().dataTask(with: newRequest, completionHandler: { (data: Data?, response: URLResponse?,  error: Error?) -> Void in
                
//                if let res = response as? HTTPURLResponse {
//                    let httpResponse = res
//
//                    callback((httpResponse.statusCode != 204))
//                } else {
//                    callback(false) // request failed (probably due to no network connection)
//                }
//            })
//
//            task.resume()
        }
    }

}
