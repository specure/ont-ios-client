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

// TODO !!!!!
public func getHistoryFilter(success: @escaping (_ filter: HistoryFilterType) -> (),
                             error failure: @escaping ErrorCallback) {
    
    ControlServer.sharedControlServer.getSettings(success: { 
    

        return
        
    }, error: failure )
}

//
//
public func getHistoryFilter()-> HistoryFilterType? {
    return ControlServer.sharedControlServer.historyFilter
}

// ONT 
public func getMeasurementServerInfo(success: @escaping (_ response: MeasurementServerInfoResponse) -> (),
                                     error failure: @escaping ErrorCallback) {
    
    ControlServer.sharedControlServer.getMeasurementServerDetails(success: { servers in
        success(servers)
        
    }, error: failure)
}

public func checkSurvey(success: @escaping (_ response: CheckSurveyResponse) -> (),
                                     error failure: @escaping ErrorCallback) {
    
    
    ControlServer.sharedControlServer.checkSurvey(success: success, error: failure)
}

/// data type alias for filters
public typealias HistoryFilterType = [String: [String]]

///
public typealias EmptyCallback = () -> ()

///
public typealias ErrorCallback = (_ error: Error) -> ()

///
public typealias IpResponseSuccessCallback = (_ ipResponse: IpResponse_Old) -> ()

///
let secureRequestPrefix = "https://"

///
class ControlServer {

    ///
    static let sharedControlServer = ControlServer()

    ///
    private let alamofireManager: Alamofire.Session

    ///
    private let settings = RMBTSettings.sharedSettings

    ///
    private var uuidQueue = DispatchQueue(label: "com.specure.nettest.uuid_queue", attributes: [])

    ///
    var version: String?

    ///
    var uuid: String?
    
    ///
    var historyFilter: HistoryFilterType?
    
    var surveySettings: SettingsReponse_Old.Settings.SurveySettings?
    var advertisingSettings: AdvertisingResponse?

    ///
    var openTestBaseURL: String?
    
    ///
    private var uuidKey: String? // TODO: unique for each control server?

    ///
    var baseUrl = "https://netcouch.specure.com/api/v1"

    ///
    private var defaultBaseUrl = "https://netcouch.specure.com/api/v1" /*"http://localhost:8080/api/v1"*/ //RMBT_CONTROL_SERVER_URL

    // TODO: HTTP/2, NGINX, IOS PROBLEM! http://stackoverflow.com/questions/36907767/nsurlerrordomain-code-1004-for-few-seconds-after-app-start-up

    //

    ///
    var mapServerBaseUrl: String?
    
    //
    
    let storeUUIDKey = "uuid_"

    ///
    private init() {
        alamofireManager = ServerHelper.configureAlamofireManager()
    }

    ///
    deinit {
        alamofireManager.session.invalidateAndCancel()
    }
    
    func clearStoredUUID() {
        baseUrl = RMBTConfig.sharedInstance.RMBT_CONTROL_SERVER_URL
        uuidKey = "\(storeUUIDKey)\(URL(string: baseUrl)!.host!)"
        
        UserDefaults.clearStoredUUID(uuidKey: uuidKey)
        self.uuid = nil
    }
    
    ///
    func updateWithCurrentSettings(success successCallback: @escaping EmptyCallback, error failure: @escaping ErrorCallback) {
        
        baseUrl = RMBTConfig.sharedInstance.RMBT_CONTROL_SERVER_URL
        uuidKey = "\(storeUUIDKey)\(URL(string: baseUrl)!.host!)"
        
        if self.uuid == nil {
            uuid = UserDefaults.checkStoredUUID(uuidKey: uuidKey)
        }
        
        // get settings of control server
        getSettings(success: {
            // check for ip version force
            if self.settings.nerdModeForceIPv6 {
                self.baseUrl = RMBTConfig.sharedInstance.RMBT_CONTROL_SERVER_IPV6_URL
            } else if self.settings.nerdModeForceIPv4 {
                self.baseUrl = RMBTConfig.sharedInstance.RMBT_CONTROL_SERVER_IPV4_URL
            }
            
            // 
            if self.settings.debugUnlocked {    
                // check for custom control server
                if self.settings.debugControlServerCustomizationEnabled {
                    let scheme = self.settings.debugControlServerUseSSL ? "https" : "http"
                    var hostname = self.settings.debugControlServerHostname
                    
                    if self.settings.debugControlServerPort != 0 && self.settings.debugControlServerPort != 80 {
                        hostname = "\(String(describing: hostname)):\(self.settings.debugControlServerPort)"
                    }
                    
//                    if let url = NSURL(scheme: scheme, host: hostname, path: "/api/v1"/*RMBT_CONTROL_SERVER_PATH*/) as URL? {
//                        self.baseUrl = url.absoluteString // !
//                        self.uuidKey = "\(self.storeUUIDKey)\(url.host!)"
//                    }
                    
                    let theUrl = NSURLComponents()
                    theUrl.host = hostname
                    theUrl.scheme = scheme
                    theUrl.path = "/api/v1"/*RMBT_CONTROL_SERVER_PATH*/
                    
                    self.baseUrl = (theUrl.url?.absoluteString)! // !
                    self.uuidKey = "\(self.storeUUIDKey)\(theUrl.host!)"
                }
            }
            
            Log.logger.info("Control Server base url = \(self.baseUrl)")

//            self.mapServerBaseUrl = RMBTConfig.sharedInstance.RMBT_MAP_SERVER_PATH_URL
            
            successCallback()
            
        }) { error in
            
            failure(error)
        }
    }
    
    //
    func getMeasurementServerDetails(success: @escaping (_ response: MeasurementServerInfoResponse) -> (),
                                     error failure: @escaping ErrorCallback) {
        
        let req = MeasurementServerInfoRequest()
        
        if let l = RMBTLocationTracker.sharedTracker.location {
            let geoLocation = GeoLocation(location: l)
            req.geoLocation = geoLocation
        }
        
//        let baseUrl = RMBTConfig.sharedInstance.RMBT_CONTROL_MEASUREMENT_SERVER_URL
//        self.request(baseUrl, .post, path: "/measurementServer", requestObject: req, success: success, error: failure)
        self.request(baseUrl, .post, path: "/measurementServer", requestObject: req, success: success, error: failure)
    }

// MARK: Advertising
    
    func getAdvertising(success successCallback: @escaping EmptyCallback, error failure: @escaping ErrorCallback) {
        ensureClientUuid(success: { (uuid) in
            let advertisingRequest = AdvertisingRequest()
            advertisingRequest.uuid = uuid
            
            if RMBTConfig.sharedInstance.RMBT_VERSION_NEW {
                successCallback()
            }
            else {
                let successFunc: (_ response: AdvertisingResponse) -> () = { response in
                    Log.logger.debug("advertising: \(String(describing: response.isShowAdvertising))")
                    self.advertisingSettings = response
                    successCallback()
                }
                self.request(.post, path: "/advertising", requestObject: advertisingRequest, success: successFunc, error: { error in
                    Log.logger.debug("advertising error")
                    
                    failure(error)
                })
            }
        }, error: failure)
    }
    
// MARK: Settings

    ///
    func getSettings(success successCallback: @escaping EmptyCallback, error failure: @escaping ErrorCallback) {
        
        let settingsRequest = SettingsRequest()
        
        settingsRequest.client = ClientSettings()
        settingsRequest.client?.clientType = "MOBILE"
        settingsRequest.client?.termsAndConditionsAccepted = true
        settingsRequest.client?.uuid = uuid
        
        ////
        // NKOM solution
        let successFunc: (_ response: SettingsReponse) -> () = { response in
            Log.logger.debug("settings: \(String(describing: response.client))")
            
            // set uuid
            self.uuid = response.client?.uuid
            
            // save uuid
            
            if let uuidKey = self.uuidKey, let u = self.uuid {
                UserDefaults.storeNewUUID(uuidKey: uuidKey, uuid: u)
            }
            // set control server version
            self.version = response.settings?.versions?.controlServerVersion
            
            // set qos test type desc
            response.qosMeasurementTypes?.forEach({ measurementType in
                if let type = measurementType.type {
                    QosMeasurementType.localizedNameDict[type] = measurementType.name
                }
            })
            
            if RMBTConfig.sharedInstance.settingsMode == .remotely {
                ///
                // No synchro = No filters
                //
                if let ipv4Server = response.settings?.controlServerIpv4Host {
                    RMBTConfig.sharedInstance.configNewCS_IPv4(server: ipv4Server)
                }
                
                //
                if let ipv6Server = response.settings?.controlServerIpv6Host {
                    RMBTConfig.sharedInstance.configNewCS_IPv6(server: ipv6Server)
                }
                
                //
                if let mapServer = response.settings?.mapServer?.host {
                    RMBTConfig.sharedInstance.configNewMapServer(server: mapServer)
                }
            }
            self.mapServerBaseUrl = RMBTConfig.sharedInstance.RMBT_MAP_SERVER_PATH_URL
            
            successCallback()
        }
        ////
        // ONT and all other project solution
        let successFuncOld: (_ response: SettingsReponse_Old) -> () = { response in
            Log.logger.debug("settings: \(response)")
            
            if let set = response.settings?.first {
                // set uuid
                if let newUUID = set.uuid {
                    self.uuid = newUUID
                }
                
                // save uuid
                if let uuidKey = self.uuidKey, let u = self.uuid {
                    UserDefaults.storeNewUUID(uuidKey: uuidKey, uuid: u)
                }
                
                self.surveySettings = set.surveySettings
                
                // set control server version
                self.version = set.versions?.controlServerVersion
                
                // set qos test type desc
                set.qosMeasurementTypes?.forEach({ measurementType in
                    if let theType = measurementType.testType, let theDesc = measurementType.testDesc {
                        if let type = QosMeasurementType(rawValue: theType.lowercased()) {
                            QosMeasurementType.localizedNameDict.updateValue(theDesc, forKey:type)
                        }
                    }
                })
                // get history filters
                self.historyFilter = set.history
                
                if RMBTConfig.sharedInstance.settingsMode == .remotely {
                    //
                    if let ipv4Server = set.urls?.ipv4IpOnly {
                        RMBTConfig.sharedInstance.configNewCS_IPv4(server: ipv4Server)
                    }
                    
                    //
                    if let ipv6Server = set.urls?.ipv6IpOnly {
                        RMBTConfig.sharedInstance.configNewCS_IPv6(server: ipv6Server)
                    }
                    
                    //
                    if let theOpenTestBase = set.urls?.opendataPrefix {
                        self.openTestBaseURL = theOpenTestBase
                    }
                    
                    //
                    if let checkip4 = set.urls?.ipv4IpCheck {
                        RMBTConfig.sharedInstance.RMBT_CHECK_IPV4_URL = checkip4
                    }
                    
                    
                    // check for map server from settings
                    if let mapServer = set.map_server {
                        let host = mapServer.host
                        let scheme = mapServer.useTls ? "https" : "http"
                        //
                        var port = (mapServer.port! as NSNumber).stringValue
                        if (port == "80" || port == "443") {
                            port = ""
                        } else {
                            port = ":\(port)"
                        }
                        
                        self.mapServerBaseUrl = "\(scheme)://\(host!)\(port)\(RMBT_MAP_SERVER_PATH)"
                        Log.logger.debug("setting map server url to \(String(describing: self.mapServerBaseUrl)) from settings request")
                    }
                } else {
                    self.mapServerBaseUrl = RMBTConfig.sharedInstance.RMBT_MAP_SERVER_PATH_URL
                }
            }
            
            successCallback()
        }

        if RMBTConfig.sharedInstance.RMBT_VERSION_NEW {
        
            request(.post, path: "/settings", requestObject: settingsRequest, success: successFunc, error: { error in
                Log.logger.debug("settings error")
                
                failure(error)
            })

        } else {
        
            let settingsRequest_Old = SettingsRequest_Old()
            settingsRequest_Old.termsAndConditionsAccepted = true
            settingsRequest_Old.termsAndConditionsAccepted_Version = 1
            settingsRequest_Old.uuid = self.uuid
            
            request(.post, path: "/settings", requestObject: settingsRequest_Old, success: successFuncOld, error: { error in
                Log.logger.debug("settings error")
                
                failure(error)
            })
        }
    }

// MARK: IP

    ///
    func getIpv4( success successCallback: @escaping IpResponseSuccessCallback, error failure: @escaping ErrorCallback) {
        getIpVersion(baseUrl: RMBTConfig.sharedInstance.RMBT_CHECK_IPV4_URL, success: successCallback, error: failure)
    }

    /// no NAT
//    func getIpv6( success successCallback: @escaping IpResponseSuccessCallback, error failure: @escaping ErrorCallback) {
//        getIpVersion(baseUrl: RMBTConfig.sharedInstance.RMBT_CONTROL_SERVER_IPV6_URL, success: successCallback, error: failure)
//    }

    ///
    func getIpVersion(baseUrl:String, success successCallback: @escaping IpResponseSuccessCallback, error failure: @escaping ErrorCallback) {

        let infoParams = IPRequest_Old()
        infoParams.uuid = self.uuid
        infoParams.plattform = "iOS"
        
        ServerHelper.request(alamofireManager, baseUrl: baseUrl, method: .post, path: "", requestObject: infoParams, success: successCallback , error: failure)
    }

// MARK: Speed measurement

    ///
    func requestSpeedMeasurement(_ speedMeasurementRequest: SpeedMeasurementRequest, success: @escaping (_ response: SpeedMeasurementResponse) -> (), error failure: @escaping ErrorCallback) {
        ensureClientUuid(success: { uuid in
            speedMeasurementRequest.uuid = uuid
            speedMeasurementRequest.anonymous = RMBTSettings.sharedSettings.anonymousModeEnabled

            Log.logger.debugExec {
                if speedMeasurementRequest.anonymous {
                    Log.logger.debug("CLIENT IS ANONYMOUS!")
                }
            }

            self.request(.post, path: "/measurements/speed", requestObject: speedMeasurementRequest, success: success, error: failure)
        }, error: failure)
    }
    
    ///
    func requestSpeedMeasurement_Old(_ speedMeasurementRequest: SpeedMeasurementRequest_Old, success: @escaping (_ response: SpeedMeasurementResponse_Old) -> (), error failure: @escaping ErrorCallback) {
        ensureClientUuid(success: { uuid in
            speedMeasurementRequest.uuid = uuid
            speedMeasurementRequest.ndt = false
            speedMeasurementRequest.time = RMBTTimestampWithNSDate(NSDate() as Date) as? UInt64
            
            self.request(.post, path: "/", requestObject: speedMeasurementRequest, success: success, error: failure)
        }, error: failure)
    }

    ///
    func submitZeroMeasurementRequests(_ measurementRequests: [ZeroMeasurementRequest], success: @escaping (_ response: SpeedMeasurementSubmitResponse) -> (), error failure: @escaping ErrorCallback) {
        ensureClientUuid(success: { uuid in
            var passedMeasurementResults: [ZeroMeasurementRequest] = []
            for measurement in measurementRequests {
                if let _ = measurement.uuid {
                    measurement.clientUuid = uuid
                    passedMeasurementResults.append(measurement)
                }
            }
            if passedMeasurementResults.count > 0 {
                self.request(.post, path: "/zeroMeasurement", requestObjects: passedMeasurementResults, key: "zero_measurement", success: success, error: failure)
            }
            else {
                failure(NSError(domain: "controlServer", code: 134534, userInfo: nil)) // give error if no uuid was provided by caller
            }
        }, error: failure)
    }
    
    ///
    func submitSpeedMeasurementResult(_ speedMeasurementResult: SpeedMeasurementResult, success: @escaping (_ response: SpeedMeasurementSubmitResponse) -> (), error failure: @escaping ErrorCallback) {
        ensureClientUuid(success: { uuid in
            if let measurementUuid = speedMeasurementResult.uuid {
                speedMeasurementResult.clientUuid = uuid
                RMBTConfig.sharedInstance.RMBT_VERSION_NEW ?
                self.request(.put, path: "/measurements/speed/\(measurementUuid)", requestObject: speedMeasurementResult, success: success, error: failure)
                :
                self.request(.post, path: "/result", requestObject: speedMeasurementResult, success: success, error: failure)
            } else {
                failure(NSError(domain: "controlServer", code: 134534, userInfo: nil)) // give error if no uuid was provided by caller
            }
        }, error: failure)
    }
    
    ///
    func submitSpeedMeasurementResult_Old(_ speedMeasurementResult: SpeedMeasurementResult, success: @escaping (_ response: SpeedMeasurementSubmitResponse) -> (), error failure: @escaping ErrorCallback) {
        ensureClientUuid(success: { uuid in
            if speedMeasurementResult.uuid != nil {
                speedMeasurementResult.clientUuid = uuid
                
                self.request(.post, path: "/result", requestObject: speedMeasurementResult, success: success, error: failure)
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
            qosMeasurementRequest.uuid = uuid
            qosMeasurementRequest.measurementUuid = measurementUuid

            self.request(.post, path: RMBTConfig.sharedInstance.RMBT_VERSION_NEW ?
                "/measurements/qos"
                :
                "/qosTestRequest"
                , requestObject: qosMeasurementRequest, success: success, error: failure)
        }, error: failure)
    }
    
    ///
    func submitQosMeasurementResult(_ qosMeasurementResult: QosMeasurementResultRequest, success: @escaping (_ response: QosMeasurementSubmitResponse) -> (), error failure: @escaping ErrorCallback) {
        ensureClientUuid(success: { uuid in
            if let measurementUuid = qosMeasurementResult.measurementUuid {
                qosMeasurementResult.clientUuid = uuid
                // qosMeasurementResult.measurementUuid = measurementUuid

                self.request(RMBTConfig.sharedInstance.RMBT_VERSION_NEW ? .put:.post, path: RMBTConfig.sharedInstance.RMBT_VERSION_NEW ? "/measurements/qos/\(measurementUuid)":"/resultQoS", requestObject: qosMeasurementResult, success: success, error: failure)
            } else {
                failure(NSError(domain: "controlServer", code: 134535, userInfo: nil)) // TODO: give error if no measurement uuid was provided by caller
            }
        }, error: failure)
    }
    
    ///
    func submitQosMeasurementResult_Old(_ qosMeasurementResult: QosMeasurementResultRequest, success: @escaping (_ response: QosMeasurementSubmitResponse) -> (), error failure: @escaping ErrorCallback) {
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
    
    /// OLD solution
    func getQOSHistoryResultWithUUID(testUuid: String, success: @escaping (_ response: QosMeasurementResultResponse) -> (), error failure: @escaping ErrorCallback) {
        ensureClientUuid(success: { _ in
            
            let r = HistoryWithQOS()
            r.testUUID = testUuid

            self.request(.post, path: "/qosTestResult", requestObject: r, success: success, error: failure)
            
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
    func getHistoryWithFilters(filters: HistoryFilterType?, length: UInt, offset: UInt, success: @escaping (_ response: HistoryWithFiltersResponse) -> (), error errorCallback: @escaping ErrorCallback) {

        ensureClientUuid(success: { uuid in
            let req = HistoryWithFiltersRequest()
            req.uuid = uuid
            req.resultLimit = NSNumber(value: length)
            req.resultOffset = NSNumber(value: offset)
            //
            if let theFilters = filters {
                for filter in theFilters {
                    //
                    if filter.key == "devices" {
                      req.devices = filter.value
                    }
                    //
                    if filter.key == "networks" {
                        req.networks = filter.value
                    }
                }
            }
            
            self.request(.post, path: "/history", requestObject: req, success: success, error: errorCallback)
        }, error: errorCallback)
    }
    
    //
    ///
    func getHistoryResultWithUUID(uuid: String, fullDetails: Bool, success: @escaping (_ response: MapMeasurementResponse_Old) -> (), error errorCallback: @escaping ErrorCallback) {
        let key = fullDetails ? "/testresultdetail" : "/testresult"
        
        ensureClientUuid(success: { theUuid in
            
            let r = HistoryWithQOS()
            r.testUUID = uuid
            
            self.request(.post, path: key, requestObject: r, success: success, error: errorCallback)
            
        }, error: { error in
            Log.logger.debug("\(error)")
            
            errorCallback(error)
        })
    }
    
    ///
    func getHistoryResultWithUUID_Full(uuid: String, success: @escaping (_ response: SpeedMeasurementDetailResultResponse) -> (), error errorCallback: @escaping ErrorCallback) {
        let key = "/testresultdetail"
        
        ensureClientUuid(success: { theUuid in
            
            let r = HistoryWithQOS()
            r.testUUID = uuid
            
            self.request(.post, path: key, requestObject: r, success: success, error: errorCallback)
            
        }, error: { error in
            Log.logger.debug("\(error)")
            
            errorCallback(error)
        })
    }
    
// MARK: Synchro

    ///
    func syncWithCode(code:String, success: @escaping (_ response: SyncCodeResponse) -> (), error failure: @escaping ErrorCallback) {
        ensureClientUuid(success: { uuid in
            let req = SyncCodeRequest()
            req.code = code
            req.uuid = uuid
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
    
    // MARK: Survey Settings
    ///
    func checkSurvey(success: @escaping (_ response: CheckSurveyResponse) -> (), error failure: @escaping ErrorCallback) {
        ensureClientUuid(success: { uuid in
            let req = CheckSurveyRequest()
            req.clientUuid = uuid
            self.request(.post, path: "/checkSurvey", requestObject: req, success: success, error: failure)
        }, error: failure)
    }
    
// MARK: Private

    ///
    private func ensureClientUuid(success successCallback: @escaping (_ uuid: String) -> (), error errorCallback: @escaping ErrorCallback) {
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
    private func requestArray<T: BasicResponse>(_ method: Alamofire.HTTPMethod, path: String, requestObject: BasicRequest?, success: @escaping (_ response: [T]) -> (), error failure: @escaping ErrorCallback) {
        ServerHelper.requestArray(alamofireManager, baseUrl: baseUrl, method: method, path: path, requestObject: requestObject, success: success, error: failure)
    }

    ///
    private func request<T: BasicResponse>(_ method: Alamofire.HTTPMethod, path: String, requestObject: BasicRequest?, success: @escaping  (_ response: T) -> (), error failure: @escaping ErrorCallback) {
        ServerHelper.request(alamofireManager, baseUrl: baseUrl, method: method, path: path, requestObject: requestObject, success: success, error: failure)
    }
    
    ///
    private func request<T: BasicResponse>(_ baseUrl: String?, _ method: Alamofire.HTTPMethod, path: String, requestObject: BasicRequest?, success: @escaping  (_ response: T) -> (), error failure: @escaping ErrorCallback) {
        ServerHelper.request(alamofireManager, baseUrl: baseUrl, method: method, path: path, requestObject: requestObject, success: success, error: failure)
    }
    
    ///
    private func request<T: BasicResponse>(_ method: Alamofire.HTTPMethod, path: String, requestObjects: [BasicRequest]?, key: String?, success: @escaping  (_ response: T) -> (), error failure: @escaping ErrorCallback) {
        ServerHelper.request(alamofireManager, baseUrl: baseUrl, method: method, path: path, requestObjects: requestObjects, key: key, success: success, error: failure)
    }

}
