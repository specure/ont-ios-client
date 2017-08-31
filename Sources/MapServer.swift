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
import CoreLocation
import Alamofire
import AlamofireObjectMapper
import ObjectMapper

///
open class MapServer {

    ///
    open static let sharedMapServer = MapServer()

    ///
    private let alamofireManager: Alamofire.SessionManager

    ///
    private let settings = RMBTSettings.sharedSettings

    ///
    private var baseUrl: String? {
        return ControlServer.sharedControlServer.mapServerBaseUrl // don't store in variable, could be changed in settings
    }

    ///
    private init() {
        alamofireManager = ServerHelper.configureAlamofireManager()
    }

    ///
    deinit {
        alamofireManager.session.invalidateAndCancel()
    }

// MARK: MapServer

    ///
    open func getMapOptions(success successCallback: @escaping (_ response: /*MapOptionResponse*/RMBTMapOptions) -> (), error failure: @escaping ErrorCallback) {
        request(.post, path: "/tiles/info", requestObject: BasicRequest(), success: { (response: MapOptionResponse) in

            // TODO: rewrite MapViewController to use new objects
            let mapOptions = RMBTMapOptions(response: response.toJSON() as NSDictionary)
            successCallback(mapOptions)

        } , error: failure)
    }

    ///
    open func getMeasurementsAtCoordinate(_ coordinate: CLLocationCoordinate2D, zoom: Int, params: [String: [String: AnyObject]], success successCallback: @escaping (_ response: [SpeedMeasurementResultResponse]) -> (), error failure: @escaping ErrorCallback) {

        let mapMeasurementRequest = MapMeasurementRequest()
        mapMeasurementRequest.coords = MapMeasurementRequest.CoordObject()
        mapMeasurementRequest.coords?.latitude = coordinate.latitude
        mapMeasurementRequest.coords?.longitude = coordinate.longitude
        mapMeasurementRequest.coords?.zoom = zoom

        mapMeasurementRequest.options = params["options"]
        mapMeasurementRequest.filter = params["filter"]

        mapMeasurementRequest.prioritizeUuid = mapMeasurementRequest.clientUuid

        // add highlight filter (my measurements filter)
        //mapMeasurementRequest.filter?["highlight"] = ControlServer.sharedControlServer.uuid

        // submit client_uuid to get measurement_uuid if tapped on an own measurement
        mapMeasurementRequest.clientUuid = ControlServer.sharedControlServer.uuid

        request(.post, path: "/tiles/markers", requestObject: mapMeasurementRequest, success: { (response: MapMeasurementResponse) in
            if let measurements = response.measurements {
                successCallback(measurements)
            } else {
                failure(NSError(domain: "no measurements", code: -12543, userInfo: nil))
            }
        }, error: failure)
    }

    ///
    open func getTileUrlForMapOverlayType(_ overlayType: String, x: UInt, y: UInt, zoom: UInt, params: [String: Any]?) -> URL? {
        if let base = baseUrl {
            // baseUrl and layer
            var urlString = base + "/tiles/\(overlayType)?path=\(zoom)/\(x)/\(y)"

            // add uuid for highlight
            if let uuid = ControlServer.sharedControlServer.uuid {
                urlString += "&highlight=\(uuid)"
            }

            // add params
            if let p = params, p.count > 0 {
                let paramString = p.map({ (key, value) in
                    let escapedKey = key.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)

                    var escapedValue: String?
                    if let v = value as? String {
                        escapedValue = v.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) // TODO: does this need a cast to string?
                    } else if let numValue = value as? NSNumber {
                        escapedValue = String(describing: numValue)
                    }

                    return "\(escapedKey ?? key)=\(escapedValue ?? value as! String)"
                }).joined(separator: "&")

                urlString += "&" + paramString
            }

            logger.debug("Generated tile url: \(urlString)")

            return URL(string: urlString)
        }

        return nil
    }

    ///
    open func getOpenTestUrl(_ openTestUuid: String, success successCallback: (_ response: String?) -> ()) {
        if let url = ControlServer.sharedControlServer.openTestBaseURL {
            let theURL = url+openTestUuid
            successCallback(theURL)
        }

        successCallback(nil)
    }

// MARK: Private

    ///
    private func opentestURLForApp(_ openTestBaseURL: String) -> String {
        // hardcoded because @lb doesn't want to provide a good solution

        let r = openTestBaseURL.startIndex..<openTestBaseURL.endIndex
        let appOpenTestBaseURL = openTestBaseURL.replacingOccurrences(of: "/opentest", with: "/app/opentest", options: NSString.CompareOptions.literal, range: r)

        return appOpenTestBaseURL
    }

    ///
    private func requestArray<T: BasicResponse>(_ method: Alamofire.HTTPMethod, path: String, requestObject: BasicRequest?, success: @escaping (_ response: [T]) -> (), error failure: @escaping ErrorCallback) {
        ServerHelper.requestArray(alamofireManager, baseUrl: baseUrl, method: method, path: path, requestObject: requestObject, success: success, error: failure)
    }

    ///
    private func request<T: BasicResponse>(_ method: Alamofire.HTTPMethod, path: String, requestObject: BasicRequest?, success: @escaping (_ response: T) -> (), error failure: @escaping ErrorCallback) {
        ServerHelper.request(alamofireManager, baseUrl: baseUrl, method: method, path: path, requestObject: requestObject, success: success, error: failure)
    }
}
