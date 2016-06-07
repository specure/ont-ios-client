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
    private var uuid: String?

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
    public func getSettings(success: EmptyCallback, error failure: NEWErrorCallback) {

        let settingsRequest = SettingsRequest()
        settingsRequest.client = SettingsResponseClient()
        settingsRequest.client?.clientType = "MOBILE"
        settingsRequest.client?.termsAndConditionsAccepted = true

        /*self.request(.POST, path: "/settings", requestObject: settingsRequest) { (response: Response<SettingsReponse, NSError>) in
            if let settingsResponse = response.result.value {
                logger.debug("settings: \(settingsResponse.client)")
                success()
            }
        }*/
    }

    func requestSpeedMeasurement(speedMeasurementRequest: SpeedMeasurementRequest, success: (response: SpeedMeasurmentResponse) -> (), error failure: NEWErrorCallback) {
        request(.POST, path: "/measurements/speed", requestObject: speedMeasurementRequest, success: success, error: failure)
    }
    
    func submitSpeedMeasurementResult(speedMeasurementResult: SpeedMeasurementResultRequest, success: (response: String) -> (), error failure: NEWErrorCallback) {
        if let uuid = speedMeasurementResult.uuid {

            let x: Alamofire.Method = .PUT
            let url = "/measurements/speed/\(uuid)"
            
            self.request(x, path: url, requestObject: speedMeasurementResult, success: { (response: SpeedMeasurmentResponse) in
                logger.debug(" !!!!!RESULT SUBMIT SUCCESS!!!!! ")
            }, error: { error in
            
            })
        }
        // TODO: else error
    }
    
    public func requestQosMeasurement(success: (response: QosMeasurmentResponse) -> (), error failure: NEWErrorCallback) {
        let qosMeasurementRequest = QosMeasurementRequest()
        
        request(.POST, path: "/measurements/qos", requestObject: qosMeasurementRequest, success: success, error: failure)
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
