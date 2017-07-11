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
public typealias EmptyCallback = () -> ()

///
public typealias ErrorCallback = (_ error: Error) -> ()

///
public typealias IpResponseSuccessCallback = (_ ipResponse: IpResponse) -> ()

///
let secureRequestPrefix = "https://"

///
class ControlServer {

    ///
    static let sharedControlServer = ControlServer()

    ///
    fileprivate let alamofireManager: Alamofire.SessionManager

    ///
    fileprivate let settings = RMBTSettings.sharedSettings

    ///
    fileprivate var uuidQueue = DispatchQueue(label: "com.specure.nettest.uuid_queue", attributes: [])

    ///
    var version: String?

    ///
    var uuid: String?

    ///
    fileprivate var uuidKey: String? // TODO: unique for each control server?

    ///
    var baseUrl = "https://netcouch.specure.com/api/v1"

    ///
    fileprivate var defaultBaseUrl = "https://netcouch.specure.com/api/v1" /*"http://localhost:8080/api/v1"*/ //RMBT_CONTROL_SERVER_URL

    // TODO: HTTP/2, NGINX, IOS PROBLEM! http://stackoverflow.com/questions/36907767/nsurlerrordomain-code-1004-for-few-seconds-after-app-start-up

    //

    ///
    var mapServerBaseUrl: String?

    ///
    fileprivate init() {
        alamofireManager = ServerHelper.configureAlamofireManager()

//        if let controlServerBaseUrlArgument = UserDefaults.standard.string(forKey: "controlServerBaseUrl") {
//            defaultBaseUrl = controlServerBaseUrlArgument + "/api/v1"
//            logger.debug("Using control server base url from arguments: \(self.defaultBaseUrl)")
//        }
    }

    ///
    deinit {
        alamofireManager.session.invalidateAndCancel()
    }
    
    ///
    func updateWithCurrentSettings() {
        
        baseUrl = RMBTConfig.sharedInstance.RMBT_CONTROL_SERVER_URL
        uuidKey = "uuid_\(URL(string: baseUrl)!.host)"
        
        // load uuid
        if let key = uuidKey {
            uuid = UserDefaults.standard.object(forKey: key) as? String
            
            logger.debugExec({
                if let uuid = self.uuid {
                    logger.debug("UUID: Found uuid \"\(uuid)\" in user defaults for key '\(key)'")
                } else {
                    logger.debug("UUID: Uuid was not found in user defaults for key '\(key)'")
                }
            })
        }
        
        
        // get settings of control server
        getSettings(success: {
            // 
            if self.settings.debugUnlocked {
                
                // check for ip version force
                if self.settings.nerdModeForceIPv6 {
                    self.baseUrl = RMBTConfig.sharedInstance.RMBT_CONTROL_SERVER_IPV6_URL
                } else if self.settings.nerdModeForceIPv4 {
                    self.baseUrl = RMBTConfig.sharedInstance.RMBT_CONTROL_SERVER_IPV4_URL
                }
                
                // check for custom control server
                if self.settings.debugControlServerCustomizationEnabled {
                    let scheme = self.settings.debugControlServerUseSSL ? "https" : "http"
                    var hostname = self.settings.debugControlServerHostname
                    
                    if self.settings.debugControlServerPort != 0 && self.settings.debugControlServerPort != 80 {
                        hostname = "\(hostname):\(self.settings.debugControlServerPort)"
                    }
                    
                    if let url = NSURL(scheme: scheme, host: hostname, path: "/api/v1"/*RMBT_CONTROL_SERVER_PATH*/) as? URL {
                        self.baseUrl = url.absoluteString // !
                        self.uuidKey = "uuid_\(url.host)"
                    }
                }
            }
            
            logger.info("Control Server base url = \(self.baseUrl)")
            
            // TODO: determine map server url!
            self.mapServerBaseUrl = RMBTConfig.sharedInstance.RMBT_MAP_SERVER_PATH_URL
            
        }) { (error) in
            // TODO: error handling?
        }



        //

    }

// MARK: Settings

    ///
    func getSettings(success successCallback: @escaping EmptyCallback, error failure: @escaping ErrorCallback) {
        
        let settingsRequest = SettingsRequest()
        
        settingsRequest.client = ClientSettings()
        settingsRequest.client?.clientType = "MOBILE"
        settingsRequest.client?.termsAndConditionsAccepted = true
        settingsRequest.client?.uuid = uuid
        
        let successFunc: (_ response: SettingsReponse) -> () = { response in
            logger.debug("settings: \(response.client)")
            
            // set uuid
            self.uuid = response.client?.uuid
            
            // save uuid
            if let uuidKey = self.uuidKey {
                UserDefaults.standard.set(self.uuid, forKey: uuidKey)
                UserDefaults.standard.synchronize()
            }
            
            logger.debug("UUID: uuid is now: \(self.uuid) for key '\(self.uuidKey)'")
            
            // set control server version
            self.version = response.settings?.versions?.controlServerVersion
            
            // set qos test type desc
            response.qosMeasurementTypes?.forEach({ measurementType in
                if let type = measurementType.type {
                    QosMeasurementType.localizedNameDict[type] = measurementType.name
                }
            })
            
            // TODO: set history filters
            
            if let ipv4Server = response.settings?.controlServerIpv4Host {
                RMBTConfig.sharedInstance.configNewCS_IPv4(server: ipv4Server)
            }
            
            if let ipv6Server = response.settings?.controlServerIpv6Host {
                RMBTConfig.sharedInstance.configNewCS_IPv6(server: ipv6Server)
            }
            
            if let mapServer = response.settings?.mapServer?.host {
                RMBTConfig.sharedInstance.configNewMapServer(server: mapServer)
            }
            
            
            successCallback()
        }
        
        let successFuncOld: (_ response: SettingsReponse_Old) -> () = { response in
            logger.debug("settings: \(response)")
            
            // set uuid
            self.uuid = response.settings?[0].uuid
            
            // save uuid
            if let uuidKey = self.uuidKey {
                UserDefaults.standard.set(self.uuid, forKey: uuidKey)
                UserDefaults.standard.synchronize()
            }
            
            logger.debug("UUID: uuid is now: \(self.uuid) for key '\(self.uuidKey)'")
            
            // set control server version
            self.version = response.settings?[0].versions?.controlServerVersion
            
            // set qos test type desc
            response.settings?[0].qosMeasurementTypes?.forEach({ measurementType in
                if let type = measurementType.testType {
                    // QosMeasurementType.localizedNameDict[type] = measurementType.testDesc
                }
            })
            
            // TODO: set history filters
            // TODO: set ip request urls, set openTestBaseUrl
            // TODO: set map server url
            
            successCallback()
        }
        
        
        
        if RMBTConfig.sharedInstance.RMBT_VERSION_NEW {
        
            request(.post, path: "/settings", requestObject: settingsRequest, success: successFunc, error: { error in
                logger.debug("settings error")
                
                // TODO
                failure(error)
            })

        } else {
        
            let settingsRequest_Old = SettingsRequest_Old()
            settingsRequest_Old.termsAndConditionsAccepted = true
            settingsRequest_Old.termsAndConditionsAccepted_Version = 1
            settingsRequest_Old.uuid = uuid
            
            request(.post, path: "/settings", requestObject: settingsRequest_Old, success: successFuncOld, error: { error in
                logger.debug("settings error")
                
                // TODO
                failure(error)
            })
        }
    }

// MARK: IP

    ///
    func getIpv4( success successCallback: @escaping IpResponseSuccessCallback, error failure: @escaping ErrorCallback) {
        getIpVersion(baseUrl: RMBTConfig.sharedInstance.RMBT_CONTROL_SERVER_IPV4_URL, success: successCallback, error: failure)
    }

    ///
    func getIpv6( success successCallback: @escaping IpResponseSuccessCallback, error failure: @escaping ErrorCallback) {
        getIpVersion(baseUrl: RMBTConfig.sharedInstance.RMBT_CONTROL_SERVER_IPV6_URL, success: successCallback, error: failure)
    }

    ///
    func getIpVersion(baseUrl:String, success successCallback: @escaping IpResponseSuccessCallback, error failure: @escaping ErrorCallback) {

        let infoParams = IPRequest()
        infoParams.uuid = ControlServer.sharedControlServer.uuid
        infoParams.product = ""
        
        ServerHelper.request(alamofireManager, baseUrl: baseUrl, method: .post, path: "/ip", requestObject: infoParams, success: successCallback , error: failure)
    }

// MARK: Speed measurement

    ///
    func requestSpeedMeasurement(_ speedMeasurementRequest: SpeedMeasurementRequest, success: @escaping (_ response: SpeedMeasurementResponse) -> (), error failure: @escaping ErrorCallback) {
        ensureClientUuid(success: { uuid in
            speedMeasurementRequest.uuid = uuid
            speedMeasurementRequest.anonymous = RMBTSettings.sharedSettings.anonymousModeEnabled

            logger.debugExec {
                if speedMeasurementRequest.anonymous {
                    logger.debug("CLIENT IS ANONYMOUS!")
                }
            }

            self.request(.post, path: "/measurements/speed", requestObject: speedMeasurementRequest, success: success, error: failure)
        }, error: failure)
    }
    
    ///
    func requestSpeedMeasurement_Old(_ speedMeasurementRequest: SpeedMeasurementRequest, success: @escaping (_ response: SpeedMeasurementResponse) -> (), error failure: @escaping ErrorCallback) {
        ensureClientUuid(success: { uuid in
            let requestParams: NSMutableDictionary = NSMutableDictionary(dictionary: [
                "ndt": false,
                "time": RMBTTimestampWithNSDate(NSDate() as Date)
                ])
            
            let req = SpeedMeasurementRequest()
            req.uuid = uuid
            req.time = RMBTTimestampWithNSDate(NSDate() as Date) as! UInt64
            

                
//            self.requestWithMethod(method: "POST", path: "", params: requestParams, success: { response in
//                
//                // TODO: check "error" in json
//                
//                let tp = RMBTTestParams(response: response as! [NSObject: AnyObject])
//                success(response: tp)
//                
//            }, error: { error, info in
//                // RMBTLog("Fetching test parameters failed with err=%@, response=%@", error, info)
//                failure
//            })
            
            self.request(.post, path: "", requestObject: speedMeasurementRequest, success: success, error: failure)
        }, error: failure)
    }

    ///
    func submitSpeedMeasurementResult(_ speedMeasurementResult: SpeedMeasurementResult, success: @escaping (_ response: SpeedMeasurementSubmitResponse) -> (), error failure: @escaping ErrorCallback) {
        ensureClientUuid(success: { uuid in
            if let measurementUuid = speedMeasurementResult.uuid {
                speedMeasurementResult.clientUuid = uuid

                self.request(.put, path: "/measurements/speed/\(measurementUuid)", requestObject: speedMeasurementResult, success: success, error: failure)
            } else {
                failure(NSError(domain: "controlServer", code: 134534, userInfo: nil)) // give error if no uuid was provided by caller
            }
        }, error: failure)
    }
    
    ///
    func submitSpeedMeasurementResult_Old(_ speedMeasurementResult: SpeedMeasurementResult, success: @escaping (_ response: SpeedMeasurementSubmitResponse) -> (), error failure: @escaping ErrorCallback) {
        ensureClientUuid(success: { uuid in
            if let measurementUuid = speedMeasurementResult.uuid {
                speedMeasurementResult.clientUuid = uuid
                
                self.request(.put, path: "/measurements/speed/\(measurementUuid)", requestObject: speedMeasurementResult, success: success, error: failure)
            } else {
                failure(NSError(domain: "controlServer", code: 134534, userInfo: nil)) // give error if no uuid was provided by caller
            }
        }, error: failure)
    }

    ///
    func getSpeedMeasurement(_ uuid: String, success: @escaping (_ response: SpeedMeasurementResultResponse) -> (), error failure: @escaping ErrorCallback) {
        ensureClientUuid(success: { _ in
            self.request(.get, path: "/measurements/speed/\(uuid)", requestObject: nil, success: success, error: failure)
        }, error: failure)
    }

    ///
    func getSpeedMeasurementDetails(_ uuid: String, success: @escaping (_ response: SpeedMeasurementDetailResultResponse) -> (), error failure: @escaping ErrorCallback) {
        ensureClientUuid(success: { _ in
            self.request(.get, path: "/measurements/speed/\(uuid)/details", requestObject: nil, success: success, error: failure)
        }, error: failure)
    }

    ///
    func disassociateMeasurement(_ measurementUuid: String, success: @escaping (_ response: SpeedMeasurementDisassociateResponse) -> (), error failure: @escaping ErrorCallback) {
        ensureClientUuid(success: { clientUuid in
            self.request(.delete, path: "/clients/\(clientUuid)/measurements/\(measurementUuid)", requestObject: nil, success: success, error: failure)
        }, error: failure)
    }

// MARK: Qos measurements

    ///
    func requestQosMeasurement(_ measurementUuid: String?, success: @escaping (_ response: QosMeasurmentResponse) -> (), error failure: @escaping ErrorCallback) {
        ensureClientUuid(success: { uuid in
            let qosMeasurementRequest = QosMeasurementRequest()

            qosMeasurementRequest.clientUuid = uuid
            qosMeasurementRequest.measurementUuid = measurementUuid

            self.request(.post, path: "/measurements/qos", requestObject: qosMeasurementRequest, success: success, error: failure)
        }, error: failure)
    }

    ///
    func submitQosMeasurementResult(_ qosMeasurementResult: QosMeasurementResultRequest, success: @escaping (_ response: QosMeasurementSubmitResponse) -> (), error failure: @escaping ErrorCallback) {
        ensureClientUuid(success: { uuid in
            if let measurementUuid = qosMeasurementResult.measurementUuid {
                qosMeasurementResult.clientUuid = uuid

                self.request(.put, path: "/measurements/qos/\(measurementUuid)", requestObject: qosMeasurementResult, success: success, error: failure)
            } else {
                failure(NSError(domain: "controlServer", code: 134535, userInfo: nil)) // TODO: give error if no measurement uuid was provided by caller
            }
        }, error: failure)
    }

    ///
    func getQosMeasurement(_ uuid: String, success: @escaping (_ response: QosMeasurementResultResponse) -> (), error failure: @escaping ErrorCallback) {
        ensureClientUuid(success: { _ in
            self.request(.get, path: "/measurements/qos/\(uuid)", requestObject: nil, success: success, error: failure)
        }, error: failure)
    }

// MARK: History

    ///
    func getMeasurementHistory(_ success: @escaping (_ response: [HistoryItem]) -> (), error failure: @escaping ErrorCallback) {
        ensureClientUuid(success: { uuid in
            self.requestArray(.get, path: "/clients/\(uuid)/measurements", requestObject: nil, success: success, error: failure)
        }, error: failure)
    }

    ///
    func getMeasurementHistory(_ timestamp: UInt64, success: @escaping (_ response: [HistoryItem]) -> (), error failure: @escaping ErrorCallback) {
        ensureClientUuid(success: { uuid in
            self.requestArray(.get, path: "/clients/\(uuid)/measurements?timestamp=\(timestamp)", requestObject: nil, success: success, error: failure)
        }, error: failure)
    }
    
    // OLD
    ///
    func getHistoryWithFilters(filters: NSDictionary?, length: UInt, offset: UInt, success: @escaping (_ response: HistoryWithFiltersResponse) -> (), error errorCallback: @escaping ErrorCallback) {
        let params: NSMutableDictionary = NSMutableDictionary(dictionary: [
            "result_offset": NSNumber(value: offset),
            "result_limit": NSNumber(value: length)
            ])
        
        if filters != nil {
            params.addEntries(from: filters! as [NSObject: AnyObject])
        }
        
        ensureClientUuid(success: { uuid in
            let req = HistoryWithFiltersRequest()
            req.uuid = uuid
            req.resultLimit = NSNumber(value: length)
            req.resultOffset = NSNumber(value: offset)
            self.request(.post, path: "/history", requestObject: req, success: success, error: errorCallback)
        }, error: errorCallback)
    }
    
// MARK: Synchro

    ///
    func syncWithCode(code:String, success: @escaping (_ response: SyncCodeResponse) -> (), error failure: @escaping ErrorCallback) {
        ensureClientUuid(success: { uuid in
        let req = SyncCodeRequest()
        req.code = code
            self.request(.post, path: "/sync", requestObject: req, success: success, error: failure)
        }, error: failure)
    }
    
    ///
    func synchGetCode(success: @escaping (_ response: GetSyncCodeResponse) -> (), error failure: @escaping ErrorCallback) {
        ensureClientUuid(success: { uuid in
            let req = GetSyncCodeRequest()
            req.uuid = uuid
            self.request(.post, path: "/sync", requestObject: req, success: success, error: failure)
        }, error: failure)
    }
    
// MARK: Private

    ///
    fileprivate func ensureClientUuid(success successCallback: @escaping (_ uuid: String) -> (), error errorCallback: @escaping ErrorCallback) {
        uuidQueue.async {
            if let uuid = self.uuid {
                successCallback(uuid)
            } else {
                self.uuidQueue.suspend()

                self.getSettings(success: {
                    self.uuidQueue.resume()

                    if let uuid = self.uuid {
                        successCallback(uuid)
                    } else {
                        errorCallback(NSError(domain: "strange error, should never happen, should have uuid by now", code: -1234345, userInfo: nil))
                    }
                }, error: { error in
                    self.uuidQueue.resume()
                    errorCallback(error)
                })
            }
        }
    }

    ///
    fileprivate func requestArray<T: BasicResponse>(_ method: Alamofire.HTTPMethod, path: String, requestObject: BasicRequest?, success: @escaping (_ response: [T]) -> (), error failure: @escaping ErrorCallback) {
        ServerHelper.requestArray(alamofireManager, baseUrl: baseUrl, method: method, path: path, requestObject: requestObject, success: success, error: failure)
    }

    ///
    fileprivate func request<T: BasicResponse>(_ method: Alamofire.HTTPMethod, path: String, requestObject: BasicRequest?, success: @escaping  (_ response: T) -> (), error failure: @escaping ErrorCallback) {
        ServerHelper.request(alamofireManager, baseUrl: baseUrl, method: method, path: path, requestObject: requestObject, success: success, error: failure)
    }

}
