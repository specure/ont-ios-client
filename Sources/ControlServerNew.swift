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

    private var uuid: String?

    ///
    private init() {

    }

    ///
    public func getIpv4(successCallback: IpResponseSuccessCallback, errorCallback: NEWErrorCallback) {
        self.getIpVersion("http://localhost:8080/api/v1/ip", successCallback: successCallback, errorCallback: errorCallback) // TODO: ipv4 url
    }

    ///
    public func getIpv6(successCallback: IpResponseSuccessCallback, errorCallback: NEWErrorCallback) {
        self.getIpVersion("http://localhost:8080/api/v1/ip", successCallback: successCallback, errorCallback: errorCallback) // TODO: ipv6 url
    }

    ///
    public func getIpVersion(url: String, successCallback: IpResponseSuccessCallback, errorCallback: NEWErrorCallback) {

        self.request(.POST, path: "/ip", requestObject: BasicRequest()) { (response: Response<IpResponse, NSError>) in
            // TODO: check error

            if let ipResponse = response.result.value {
                successCallback(ipResponse: ipResponse)
            }

            /*if let error = response.error {
             errorCallback(error)
             }*/
        }
    }

    ///
    public func getSettings(success: EmptyCallback, error failure: NEWErrorCallback) {

        let settingsRequest = SettingsRequest()
        settingsRequest.client = SettingsResponseClient()
        settingsRequest.client?.clientType = "MOBILE"
        settingsRequest.client?.termsAndConditionsAccepted = true

        self.request(.POST, path: "/settings", requestObject: settingsRequest) { (response: Response<SettingsReponse, NSError>) in
            if let settingsResponse = response.result.value {
                logger.debug("settings: \(settingsResponse.client)")
                success()
            }
        }
    }

    ///
    private func request<T: Mappable>(method: Alamofire.Method, path: String, requestObject: BasicRequest, callback: (response: Response<T, NSError>) -> ()) {
        // add basic request values (TODO: make device independent -> for osx, tvos)
        BasicRequestBuilder.addBasicRequestValues(requestObject)

        let parameters = Mapper().toJSON(requestObject)

        logger.debug {
            if let jsonString = Mapper().toJSONString(requestObject, prettyPrint: true) {
                return "Requesting \(path) with object: \n\(jsonString)"
            }

            return "Requesting \(path) with object: <json serialization failed>"
        }

        Alamofire.request(method, "http://localhost:8080/api/v1\(path)", parameters: parameters, encoding: .JSON).responseObject { (response: Response<T, NSError>) in
            // TODO: check error

            if let responseObj: T = response.result.value {

                logger.debug {
                    if let jsonString = Mapper().toJSONString(responseObj, prettyPrint: true) {
                        return "Response for \(path) with object: \n\(jsonString)"
                    }

                    return "Response for \(path) with object: <json serialization failed>"
                }

                callback(response: response)
            }
        }
    }

}
