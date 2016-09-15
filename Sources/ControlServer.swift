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
public typealias EmptyCallback = () -> ()

///
public typealias ErrorCallback = (error: NSError) -> ()

///
public typealias IpResponseSuccessCallback = (ipResponse: IpResponse) -> ()

///
class ControlServer {

    ///
    static let sharedControlServer = ControlServer()

    ///
    private let alamofireManager: Alamofire.Manager

    ///
    private let settings = RMBTSettings.sharedSettings

    ///
    private var uuidQueue = dispatch_queue_create("com.specure.nettest.uuid_queue", DISPATCH_QUEUE_SERIAL)

    ///
    var version: String?

    ///
    var uuid: String?

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

    ///
    private init() {
        alamofireManager = ServerHelper.configureAlamofireManager()

        if let controlServerBaseUrlArgument = NSUserDefaults.standardUserDefaults().stringForKey("controlServerBaseUrl") {
            defaultBaseUrl = controlServerBaseUrlArgument + "/api/v1"
            logger.debug("Using control server base url from arguments: \(defaultBaseUrl)")
        }
    }

    ///
    deinit {
        alamofireManager.session.invalidateAndCancel()
    }

    ///
    func updateWithCurrentSettings() { // TODO: how does app set the control server url? need param?
        // configure control server url

        baseUrl = defaultBaseUrl
        uuidKey = "uuid_\(NSURL(string: baseUrl)!.host)" // !

        if settings.debugUnlocked {

            // check for ip version force
            if settings.nerdModeForceIPv6 { // TODO
                baseUrl = "https://netcouch.specure.com/api/v1"//RMBT_CONTROL_SERVER_IPV6_URL
            } else if settings.nerdModeForceIPv4 { // TODO
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
                    baseUrl = url.absoluteString! // !
                    uuidKey = "uuid_\(url.host)"
                }
            }
        }

        logger.info("Control Server base url = \(baseUrl)")

        // TODO: determine map server url!
        mapServerBaseUrl = "https://netcouch.specure.com/RMBTMapServer"

        //

        // load uuid
        if let key = uuidKey {
            uuid = NSUserDefaults.standardUserDefaults().objectForKey(key) as? String

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
            // do nothing
        }) { (error) in
            // TODO: error handling?
        }
    }

// MARK: Settings

    ///
    func getSettings(success successCallback: EmptyCallback, error failure: ErrorCallback) {
        let settingsRequest = SettingsRequest()

        settingsRequest.client = ClientSettings()
        settingsRequest.client?.clientType = "MOBILE"
        settingsRequest.client?.termsAndConditionsAccepted = true
        settingsRequest.client?.uuid = uuid

        let successFunc: (response: SettingsReponse) -> () = { response in
            logger.debug("settings: \(response.client)")

            // set uuid
            self.uuid = response.client?.uuid

            // save uuid
            if let uuidKey = self.uuidKey {
                NSUserDefaults.standardUserDefaults().setObject(self.uuid, forKey: uuidKey)
                NSUserDefaults.standardUserDefaults().synchronize()
            }

            logger.debug("UUID: uuid is now: \(self.uuid) for key '\(self.uuidKey)'")

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
    func getIpv4(success successCallback: IpResponseSuccessCallback, error failure: ErrorCallback) {
        getIpVersion(success: successCallback, error: failure) // TODO: ipv4 url
    }

    ///
    func getIpv6(success successCallback: IpResponseSuccessCallback, error failure: ErrorCallback) {
        getIpVersion(success: successCallback, error: failure) // TODO: ipv6 url
    }

    ///
    func getIpVersion(success successCallback: IpResponseSuccessCallback, error failure: ErrorCallback) {
        request(.POST, path: "/ip", requestObject: BasicRequest(), success: successCallback, error: failure)
    }

// MARK: Speed measurement

    ///
    func requestSpeedMeasurement(speedMeasurementRequest: SpeedMeasurementRequest, success: (response: SpeedMeasurementResponse) -> (), error failure: ErrorCallback) {
        ensureClientUuid(success: { uuid in
            speedMeasurementRequest.uuid = uuid
            speedMeasurementRequest.anonymous = RMBTSettings.sharedSettings.anonymousModeEnabled

            logger.debugExec {
                if speedMeasurementRequest.anonymous {
                    logger.debug("CLIENT IS ANONYMOUS!")
                }
            }

            self.request(.POST, path: "/measurements/speed", requestObject: speedMeasurementRequest, success: success, error: failure)
        }, error: failure)
    }

    ///
    func submitSpeedMeasurementResult(speedMeasurementResult: SpeedMeasurementResult, success: (response: SpeedMeasurementSubmitResponse) -> (), error failure: ErrorCallback) {
        ensureClientUuid(success: { uuid in
            if let measurementUuid = speedMeasurementResult.uuid {
                speedMeasurementResult.clientUuid = uuid

                self.request(.PUT, path: "/measurements/speed/\(measurementUuid)", requestObject: speedMeasurementResult, success: success, error: failure)
            } else {
                failure(error: NSError(domain: "controlServer", code: 134534, userInfo: nil)) // give error if no uuid was provided by caller
            }
        }, error: failure)
    }

    ///
    func getSpeedMeasurement(uuid: String, success: (response: SpeedMeasurementResultResponse) -> (), error failure: ErrorCallback) {
        ensureClientUuid(success: { _ in
            self.request(.GET, path: "/measurements/speed/\(uuid)", requestObject: nil, success: success, error: failure)
        }, error: failure)
    }

    ///
    func getSpeedMeasurementDetails(uuid: String, success: (response: SpeedMeasurementDetailResultResponse) -> (), error failure: ErrorCallback) {
        ensureClientUuid(success: { _ in
            self.request(.GET, path: "/measurements/speed/\(uuid)/details", requestObject: nil, success: success, error: failure)
        }, error: failure)
    }

    ///
    func disassociateMeasurement(measurementUuid: String, success: (response: SpeedMeasurementDisassociateResponse) -> (), error failure: ErrorCallback) {
        ensureClientUuid(success: { clientUuid in
            self.request(.DELETE, path: "/clients/\(clientUuid)/measurements/\(measurementUuid)", requestObject: nil, success: success, error: failure)
        }, error: failure)
    }

// MARK: Qos measurements

    ///
    func requestQosMeasurement(measurementUuid: String?, success: (response: QosMeasurmentResponse) -> (), error failure: ErrorCallback) {
        ensureClientUuid(success: { uuid in
            let qosMeasurementRequest = QosMeasurementRequest()

            qosMeasurementRequest.clientUuid = uuid
            qosMeasurementRequest.measurementUuid = measurementUuid

            self.request(.POST, path: "/measurements/qos", requestObject: qosMeasurementRequest, success: success, error: failure)
        }, error: failure)
    }

    ///
    func submitQosMeasurementResult(qosMeasurementResult: QosMeasurementResultRequest, success: (response: QosMeasurementSubmitResponse) -> (), error failure: ErrorCallback) {
        ensureClientUuid(success: { uuid in
            if let measurementUuid = qosMeasurementResult.measurementUuid {
                qosMeasurementResult.clientUuid = uuid

                self.request(.PUT, path: "/measurements/qos/\(measurementUuid)", requestObject: qosMeasurementResult, success: success, error: failure)
            } else {
                failure(error: NSError(domain: "controlServer", code: 134535, userInfo: nil)) // TODO: give error if no measurement uuid was provided by caller
            }
        }, error: failure)
    }

    ///
    func getQosMeasurement(uuid: String, success: (response: QosMeasurementResultResponse) -> (), error failure: ErrorCallback) {
        ensureClientUuid(success: { _ in
            self.request(.GET, path: "/measurements/qos/\(uuid)", requestObject: nil, success: success, error: failure)
        }, error: failure)
    }

// MARK: History

    ///
    func getMeasurementHistory(success: (response: [HistoryItem]) -> (), error failure: ErrorCallback) {
        ensureClientUuid(success: { uuid in
            self.requestArray(.GET, path: "/clients/\(uuid)/measurements", requestObject: nil, success: success, error: failure)
        }, error: failure)
    }

    ///
    func getMeasurementHistory(timestamp: UInt64, success: (response: [HistoryItem]) -> (), error failure: ErrorCallback) {
        ensureClientUuid(success: { uuid in
            self.requestArray(.GET, path: "/clients/\(uuid)/measurements?timestamp=\(timestamp)", requestObject: nil, success: success, error: failure)
        }, error: failure)
    }

// MARK: Private

    ///
    private func ensureClientUuid(success successCallback: (uuid: String) -> (), error errorCallback: ErrorCallback) {
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
    private func requestArray<T: BasicResponse>(method: Alamofire.Method, path: String, requestObject: BasicRequest?, success: (response: [T]) -> (), error failure: ErrorCallback) {
        ServerHelper.requestArray(alamofireManager, baseUrl: baseUrl, method: method, path: path, requestObject: requestObject, success: success, error: failure)
    }

    ///
    private func request<T: BasicResponse>(method: Alamofire.Method, path: String, requestObject: BasicRequest?, success: (response: T) -> (), error failure: ErrorCallback) {
        ServerHelper.request(alamofireManager, baseUrl: baseUrl, method: method, path: path, requestObject: requestObject, success: success, error: failure)
    }

}
