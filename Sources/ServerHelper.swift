/*****************************************************************************************************
 * Copyright 2016 SPECURE GmbH
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
import AlamofireObjectMapper
import ObjectMapper

///
class ServerHelper {

    ///
    class func configureAlamofireManager() -> Alamofire.Manager {
        let configuration = NSURLSessionConfiguration.ephemeralSessionConfiguration() //defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = 30 // seconds
        configuration.timeoutIntervalForResource = 30

        configuration.allowsCellularAccess = true
        configuration.HTTPShouldUsePipelining = true

        // Set user agent
        if let userAgent = NSUserDefaults.standardUserDefaults().stringForKey("UserAgent") {
            configuration.HTTPAdditionalHeaders = [
                "User-Agent": userAgent
            ]
        }

        return Alamofire.Manager(configuration: configuration)
    }

    ///
    class func requestArray<T: BasicResponse>(manager: Alamofire.Manager, baseUrl: String?, method: Alamofire.Method, path: String, requestObject: BasicRequest?, success: (response: [T]) -> (), error failure: ErrorCallback) {
        // add basic request values (TODO: make device independent -> for osx, tvos)

        var parameters: [String: AnyObject]?

        if let reqObj = requestObject {
            BasicRequestBuilder.addBasicRequestValues(reqObj)

            parameters = Mapper().toJSON(reqObj)

            logger.debug {
                if let jsonString = Mapper().toJSONString(reqObj, prettyPrint: true) {
                    return "Requesting \(path) with object: \n\(jsonString)"
                }

                return "Requesting \(path) with object: <json serialization failed>"
            }
        }

        var encoding: ParameterEncoding = .JSON
        if method == .GET || method == .DELETE { // GET and DELETE request don't support JSON bodies...
            encoding = .URL
        }

        manager
            .request(method, (baseUrl != nil ? baseUrl! : "") + path, parameters: parameters, encoding: encoding) // maybe use alamofire router later? (https://grokswift.com/router/)
            .validate() // https://github.com/Alamofire/Alamofire#validation // need custom code to get body from error (see https://github.com/Alamofire/Alamofire/issues/233)
            /*.responseString { response in
                logger.debug {
                    debugPrint(response)
                    return "Response for \(path): \n\(response.result.value)"
                }
            }*/
            .responseArray { (response: Response<[T], NSError>) in
                switch response.result {
                case .Success:
                    if let responseArray: [T] = response.result.value {

                        logger.debug {
                            debugPrint(response)

                            if let jsonString = Mapper().toJSONString(responseArray, prettyPrint: true) {
                                return "Response for \(path) with object: \n\(jsonString)"
                            }

                            return "Response for \(path) with object: <json serialization failed>"
                        }

                        success(response: responseArray)
                    }
                case .Failure(let error):
                    logger.debug("\(error)") // TODO: error callback

                    /*if let responseObj = response.result.value as? String {
                     logger.debug("error msg from server: \(responseObj)")
                     }*/

                    failure(error: error)
                }
        }
    }

    ///
    class func request<T: BasicResponse>(manager: Alamofire.Manager, baseUrl: String?, method: Alamofire.Method, path: String, requestObject: BasicRequest?, success: (response: T) -> (), error failure: ErrorCallback) {
        // add basic request values (TODO: make device independent -> for osx, tvos)

        var parameters: [String: AnyObject]?

        if let reqObj = requestObject {
            BasicRequestBuilder.addBasicRequestValues(reqObj)

            parameters = Mapper().toJSON(reqObj)

            logger.debug {
                if let jsonString = Mapper().toJSONString(reqObj, prettyPrint: true) {
                    return "Requesting \(path) with object: \n\(jsonString)"
                }

                return "Requesting \(path) with object: <json serialization failed>"
            }
        }

        var encoding: ParameterEncoding = .JSON
        if method == .GET || method == .DELETE { // GET and DELETE request don't support JSON bodies...
            encoding = .URL
        }

        manager
            .request(method, (baseUrl != nil ? baseUrl! : "") + path, parameters: parameters, encoding: encoding) // maybe use alamofire router later? (https://grokswift.com/router/)
            .validate() // https://github.com/Alamofire/Alamofire#validation // need custom code to get body from error (see https://github.com/Alamofire/Alamofire/issues/233)
            /*.responseString { response in
                logger.debug {
                    debugPrint(response)
                    return "Response for \(path): \n\(response.result.value)"
                }
            }*/
            .responseObject { (response: Response<T, NSError>) in
                switch response.result {
                case .Success:
                    if let responseObj: T = response.result.value {

                        logger.debug {
                            debugPrint(response)

                            if let jsonString = Mapper().toJSONString(responseObj, prettyPrint: true) {
                                return "Response for \(path) with object: \n\(jsonString)"
                            }

                            return "Response for \(path) with object: <json serialization failed>"
                        }

                        success(response: responseObj)
                    }
                case .Failure(let error):
                    logger.debug("\(error)") // TODO: error callback

                    /*if let responseObj = response.result.value as? String {
                     logger.debug("error msg from server: \(responseObj)")
                     }*/

                    failure(error: error)
                }
        }
    }
}
