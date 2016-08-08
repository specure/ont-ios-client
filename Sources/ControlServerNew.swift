//
//  ControlServerNew.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 31.05.16.
//
//

import Foundation
import Alamofire
import AlamofireObjectMapper
import ObjectMapper

///
public typealias IpResponseSuccessCallback = (ipResponse: IpResponse) -> ()

///
public typealias NEWErrorCallback = (error: NSError) -> ()

///
public class ControlServerNew {

    ///
    public static let sharedControlServer = ControlServerNew()

    ///
    private let alamofireManager: Alamofire.Manager

    ///
    private let settings = RMBTSettings.sharedSettings()

    ///
    private var uuidQueue = dispatch_queue_create("com.specure.nettest.uuid_queue", DISPATCH_QUEUE_SERIAL)

    ///
    public var version: String?

    ///
    public var uuid: String?

    ///
    private var uuidKey: String? // TODO: unique for each control server?

    ///
    var baseUrl = "https://netcouch.specure.com/api/v1"

    ///
    private let defaultBaseUrl = /*"http://10.9.8.160:8080/api/v1"*/ "http://localhost:8080/api/v1"
    // /*"https://netcouch.specure.com/api/v1"*/ "http://netcouch.eh0.alladin:8080/control-server/api/v1" // "https://netcouch.specure.com/api/v1"//RMBT_CONTROL_SERVER_URL

    // TODO: HTTP/2, NGINX, IOS PROBLEM! http://stackoverflow.com/questions/36907767/nsurlerrordomain-code-1004-for-few-seconds-after-app-start-up

    ///
    private init() {
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

        alamofireManager = Alamofire.Manager(configuration: configuration)
    }

    ///
    deinit {
        alamofireManager.session.invalidateAndCancel()
    }

    ///
    public func updateWithCurrentSettings() { // TODO: how does app set the control server url? need param?
        // configure control server url

        baseUrl = defaultBaseUrl
        uuidKey = "uuid_\(NSURL(string: baseUrl)!.host)" // !

        if settings.debugUnlocked {

            // check for ip version force
            if settings.debugForceIPv6 {
                baseUrl = "https://netcouch.specure.com/api/v1"//RMBT_CONTROL_SERVER_IPV6_URL
            } else if settings.forceIPv4 {
                baseUrl = "https://netcouch.specure.com/api/v1"//RMBT_CONTROL_SERVER_IPV4_URL
            }

            // check for custom control server
            if settings.debugControlServerCustomizationEnabled {
                let scheme = settings.debugControlServerUseSSL ? "https" : "http"
                var hostname = settings.debugControlServerHostname

                if settings.debugControlServerPort != 0 && settings.debugControlServerPort != 80 {
                    hostname = "\(hostname):\(settings.debugControlServerPort)"
                }

                if let url = NSURL(scheme: scheme, host: hostname, path: "/api/v1"/*RMBT_CONTROL_SERVER_PATH*/) {
                    baseUrl = url.absoluteString
                    uuidKey = "uuid_\(url.host)"
                }
            }
        }

        logger.info("Control Server base url = \(baseUrl)")

        // TODO: determine map server url!

        //

        // load uuid
        if let key = uuidKey {
            uuid = NSUserDefaults.standardUserDefaults().objectForKey(key) as? String

            logger.debugExec({
                if let uuid = self.uuid {
                    logger.debug("UUID: Found uuid \"\(uuid)\" in user defaults")
                } else {
                    logger.debug("UUID: Uuid was not found in user defaults")
                }
            })
        }

        // get settings of control server
        getSettings(success: {
            // do nothing
        }) { (error) in
            // TODO: error handling?
        }
    }

// MARK: Settings

    ///
    public func getSettings(success successCallback: EmptyCallback, error failure: NEWErrorCallback) {
        let settingsRequest = SettingsRequest()

        settingsRequest.client = ClientSettings()
        settingsRequest.client?.clientType = "MOBILE"
        settingsRequest.client?.termsAndConditionsAccepted = true
        settingsRequest.client?.uuid = uuid

        let successFunc: (response: SettingsReponse) -> () = { response in
            logger.debug("settings: \(response.client)")

            // set uuid
            self.uuid = response.client?.uuid

            // safe uuid
            if let uuidKey = self.uuidKey {
                NSUserDefaults.standardUserDefaults().setObject(self.uuid, forKey: uuidKey)
                NSUserDefaults.standardUserDefaults().synchronize()
            }

            logger.debug("UUID: uuid is now: \(self.uuid)")

            // set control server version
            self.version = response.settings?.versions?.controlServerVersion

            // set qos test type desc
            response.qosMeasurementTypes?.forEach({ measurementType in
                if let type = measurementType.type {
                    QOSMeasurementType.localizedNameDict[type] = measurementType.name
                }
            })

            // TODO: set history filters
            // TODO: set ip request urls, set openTestBaseUrl
            // TODO: set map server url

            successCallback()
        }

        request(.POST, path: "/settings", requestObject: settingsRequest, success: successFunc, error: { error in
            logger.debug("settings error")

            // TODO
            failure(error: error)
        })
    }

// MARK: IP

    ///
    public func getIpv4(success successCallback: IpResponseSuccessCallback, error failure: NEWErrorCallback) {
        getIpVersion(success: successCallback, error: failure) // TODO: ipv4 url
    }

    ///
    public func getIpv6(success successCallback: IpResponseSuccessCallback, error failure: NEWErrorCallback) {
        getIpVersion(success: successCallback, error: failure) // TODO: ipv6 url
    }

    ///
    public func getIpVersion(success successCallback: IpResponseSuccessCallback, error failure: NEWErrorCallback) {
        request(.POST, path: "/ip", requestObject: BasicRequest(), success: successCallback, error: failure)
    }

// MARK: Speed measurement

    ///
    func requestSpeedMeasurement(speedMeasurementRequest: SpeedMeasurementRequest, success: (response: SpeedMeasurementResponse) -> (), error failure: NEWErrorCallback) {
        ensureUuid(success: { uuid in
            speedMeasurementRequest.uuid = uuid

            self.request(.POST, path: "/measurements/speed", requestObject: speedMeasurementRequest, success: success, error: failure)
        }, error: failure)
    }

    ///
    func submitSpeedMeasurementResult(speedMeasurementResult: SpeedMeasurementResult, success: (response: SpeedMeasurementSubmitResponse) -> (), error failure: NEWErrorCallback) {
        ensureUuid(success: { uuid in
            if let measurementUuid = speedMeasurementResult.uuid {
                speedMeasurementResult.clientUuid = uuid

                self.request(.PUT, path: "/measurements/speed/\(measurementUuid)", requestObject: speedMeasurementResult, success: success, error: failure)
            } else {
                failure(error: NSError(domain: "controlServer", code: 134534, userInfo: nil)) // give error if no uuid was provided by caller
            }
        }, error: failure)
    }

    ///
    public func getSpeedMeasurement(uuid: String, success: (response: SpeedMeasurementResultResponse) -> (), error failure: NEWErrorCallback) {
        ensureUuid(success: { _ in
            self.request(.GET, path: "/measurements/speed/\(uuid)", requestObject: nil, success: success, error: failure)
        }, error: failure)
    }

    ///
    public func getSpeedMeasurementDetails(uuid: String, success: (response: SpeedMeasurementDetailResultResponse) -> (), error failure: NEWErrorCallback) {
        ensureUuid(success: { _ in
            self.request(.GET, path: "/measurements/speed/\(uuid)?details=true", requestObject: nil, success: success, error: failure)
        }, error: failure)
    }

// MARK: Qos measurements

    ///
    func requestQosMeasurement(measurementUuid: String?, success: (response: QosMeasurmentResponse) -> (), error failure: NEWErrorCallback) {
        ensureUuid(success: { uuid in
            let qosMeasurementRequest = QosMeasurementRequest()

            qosMeasurementRequest.clientUuid = uuid
            qosMeasurementRequest.measurementUuid = measurementUuid

            self.request(.POST, path: "/measurements/qos", requestObject: qosMeasurementRequest, success: success, error: failure)
        }, error: failure)
    }

    ///
    func submitQosMeasurementResult(qosMeasurementResult: QosMeasurementResultRequest, success: (response: QosMeasurementSubmitResponse) -> (), error failure: NEWErrorCallback) {
        ensureUuid(success: { uuid in
            if let measurementUuid = qosMeasurementResult.measurementUuid {
                qosMeasurementResult.clientUuid = uuid

                self.request(.PUT, path: "/measurements/qos/\(measurementUuid)", requestObject: qosMeasurementResult, success: success, error: failure)
            } else {
                failure(error: NSError(domain: "controlServer", code: 134535, userInfo: nil)) // TODO: give error if no measurement uuid was provided by caller
            }
        }, error: failure)
    }

    ///
    public func getQosMeasurement(uuid: String, success: (response: QosMeasurementResultResponse) -> (), error failure: NEWErrorCallback) {
        ensureUuid(success: { _ in
            self.request(.GET, path: "/measurements/qos/\(uuid)", requestObject: nil, success: success, error: failure)
        }, error: failure)
    }

// MARK: History

    ///
    public func getMeasurementHistory(success: (response: [HistoryItem]) -> (), error failure: NEWErrorCallback) {
        ensureUuid(success: { uuid in
            self.requestArray(.GET, path: "/clients/\(uuid)/measurements", requestObject: nil, success: success, error: failure)
        }, error: failure)
    }

// MARK: Private

    ///
    private func ensureUuid(success successCallback: (uuid: String) -> (), error errorCallback: NEWErrorCallback) {
        dispatch_async(uuidQueue) {
            if let uuid = self.uuid {
                successCallback(uuid: uuid)
            } else {
                dispatch_suspend(self.uuidQueue)

                self.getSettings(success: {
                    dispatch_resume(self.uuidQueue)

                    if let uuid = self.uuid {
                        successCallback(uuid: uuid)
                    } else {
                        errorCallback(error: NSError(domain: "strange error, should never happen, should have uuid by now", code: -1234345, userInfo: nil))
                    }
                }, error: { error in
                    dispatch_resume(self.uuidQueue)
                    errorCallback(error: error)
                })
            }
        }
    }

    ///
    private func requestArray<T: BasicResponse>(method: Alamofire.Method, path: String, requestObject: BasicRequest?, success: (response: [T]) -> (), error failure: NEWErrorCallback) {
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
        if method == .GET { // GET request don't support JSON bodies...
            encoding = .URL
        }

        alamofireManager
            .request(method, baseUrl + path, parameters: parameters, encoding: encoding) // maybe use alamofire router later? (https://grokswift.com/router/)
            .validate() // https://github.com/Alamofire/Alamofire#validation // need custom code to get body from error (see https://github.com/Alamofire/Alamofire/issues/233)
            .responseArray { (response: Response<[T], NSError>) in
                switch response.result {
                case .Success:
                    if let responseArray: [T] = response.result.value {

                        logger.debug {
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
    private func request<T: BasicResponse>(method: Alamofire.Method, path: String, requestObject: BasicRequest?, success: (response: T) -> (), error failure: NEWErrorCallback) {
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
        if method == .GET { // GET request don't support JSON bodies...
            encoding = .URL
        }

        alamofireManager
            .request(method, baseUrl + path, parameters: parameters, encoding: encoding) // maybe use alamofire router later? (https://grokswift.com/router/)
            .validate() // https://github.com/Alamofire/Alamofire#validation // need custom code to get body from error (see https://github.com/Alamofire/Alamofire/issues/233)
            .responseObject { (response: Response<T, NSError>) in
                switch response.result {
                case .Success:
                    if let responseObj: T = response.result.value {

                        logger.debug {
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
