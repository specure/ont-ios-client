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
    private var uuid: String? // TODO: store on device (load on launch)

    ///
    private init() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        configuration.timeoutIntervalForRequest = 10 // seconds
        configuration.timeoutIntervalForResource = 10
        
        configuration.allowsCellularAccess = true
        
        alamofireManager = Alamofire.Manager(configuration: configuration)
    }

    ///
    public func getIpv4(success successCallback: IpResponseSuccessCallback, error failure: NEWErrorCallback) {
        self.getIpVersion("http://localhost:8080/api/v1/ip", success: successCallback, error: failure) // TODO: ipv4 url
    }

    ///
    public func getIpv6(success successCallback: IpResponseSuccessCallback, error failure: NEWErrorCallback) {
        self.getIpVersion("http://localhost:8080/api/v1/ip", success: successCallback, error: failure) // TODO: ipv6 url
    }

    ///
    public func getIpVersion(url: String, success successCallback: IpResponseSuccessCallback, error failure: NEWErrorCallback) {

        self.request(.POST, path: "/ip", requestObject: BasicRequest(), success: successCallback, error: failure)
    }

    ///
    public func getSettings(success successCallback: EmptyCallback, error failure: NEWErrorCallback) {

        let settingsRequest = SettingsRequest()
        settingsRequest.client = SettingsResponseClient()
        settingsRequest.client?.clientType = "MOBILE"
        settingsRequest.client?.termsAndConditionsAccepted = true
        settingsRequest.client?.uuid = uuid

        let successFunc: (response: SettingsReponse) -> () = { response in
            logger.debug("settings: \(response.client)")
            
            self.uuid = response.client?.uuid
            
            logger.debug("uuid is now: \(self.uuid)")
            
            successCallback()
        }
        
        request(.POST, path: "/settings", requestObject: settingsRequest, success: successFunc, error: { error in
            logger.debug("settings error")
            
            // TODO
            failure(error: error)
        })
    }

// MARK: Speed measurement
    
    ///
    func requestSpeedMeasurement(speedMeasurementRequest: SpeedMeasurementRequest, success: (response: SpeedMeasurmentResponse) -> (), error failure: NEWErrorCallback) {
        speedMeasurementRequest.uuid = self.uuid
        
        request(.POST, path: "/measurements/speed", requestObject: speedMeasurementRequest, success: success, error: failure)
    }
    
    ///
    func submitSpeedMeasurementResult(speedMeasurementResult: SpeedMeasurementResultRequest, success: (response: SpeedMeasurementSubmitResponse) -> (), error failure: NEWErrorCallback) {
        
        if let uuid = speedMeasurementResult.uuid {
            speedMeasurementResult.clientUuid = self.uuid
            
            request(.PUT, path: "/measurements/speed/\(uuid)", requestObject: speedMeasurementResult, success: success, error: failure)
        } else {
            failure(error: NSError(domain: "controlServer", code: 134534, userInfo: nil)) // give error if no uuid was provided by caller
        }
    }
    
// MARK: Qos measurements
    
    ///
    func requestQosMeasurement(measurementUuid: String?, success: (response: QosMeasurmentResponse) -> (), error failure: NEWErrorCallback) {
        let qosMeasurementRequest = QosMeasurementRequest()
        
        qosMeasurementRequest.clientUuid = uuid
        qosMeasurementRequest.measurementUuid = measurementUuid
        
        request(.POST, path: "/measurements/qos", requestObject: qosMeasurementRequest, success: success, error: failure)
    }
    
    ///
    func submitQosMeasurementResult(qosMeasurementResult: QosMeasurementResultRequest, success: (response: QosMeasurementSubmitResponse) -> (), error failure: NEWErrorCallback) {
        if let measurementUuid = qosMeasurementResult.measurementUuid {
            qosMeasurementResult.clientUuid = self.uuid
            
            self.request(.PUT, path: "/measurements/qos/\(measurementUuid)", requestObject: qosMeasurementResult, success: success, error: failure)
        } else {
            failure(error: NSError(domain: "controlServer", code: 134535, userInfo: nil)) // give error if no measurement uuid was provided by caller
        }
    }
    
// MARK: Private
    
    ///
    private func request<T: Mappable>(method: Alamofire.Method, path: String, requestObject: BasicRequest, success: (response: T) -> (), error failure: NEWErrorCallback) {
        // add basic request values (TODO: make device independent -> for osx, tvos)
        BasicRequestBuilder.addBasicRequestValues(requestObject)
        
        let parameters = Mapper().toJSON(requestObject)

        logger.debug {
            if let jsonString = Mapper().toJSONString(requestObject, prettyPrint: true) {
                return "Requesting \(path) with object: \n\(jsonString)"
            }

            return "Requesting \(path) with object: <json serialization failed>"
        }
        
        alamofireManager
            .request(method, "http://localhost:8080/api/v1\(path)", parameters: parameters, encoding: .JSON)
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
