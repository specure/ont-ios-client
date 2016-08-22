//
//  MapServer.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 10.08.16.
//
//

import Foundation
import CoreLocation
import Alamofire
import AlamofireObjectMapper
import ObjectMapper

///
public class MapServer {

    ///
    public static let sharedMapServer = MapServer()

    ///
    private let alamofireManager: Alamofire.Manager

    ///
    private let settings = RMBTSettings.sharedSettings()

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
    public func getMapOptions(success successCallback: (response: /*MapOptionResponse*/RMBTMapOptions) -> (), error failure: ErrorCallback) {
        request(.POST, path: "/tiles/info", requestObject: BasicRequest(), success: { (response: MapOptionResponse) in

            // TODO: rewrite MapViewController to use new objects
            let mapOptions = RMBTMapOptions(response: Mapper().toJSON(response))
            successCallback(response: mapOptions)

        }, error: failure)
    }

    ///
    public func getMeasurementsAtCoordinate(coordinate: CLLocationCoordinate2D, zoom: Int, params: [String: [String: AnyObject]], success successCallback: (response: [SpeedMeasurementResultResponse]) -> (), error failure: ErrorCallback) {

        let mapMeasurementRequest = MapMeasurementRequest()
        mapMeasurementRequest.coords = MapMeasurementRequest.CoordObject()
        mapMeasurementRequest.coords?.latitude = coordinate.latitude
        mapMeasurementRequest.coords?.longitude = coordinate.longitude
        mapMeasurementRequest.coords?.zoom = zoom

        mapMeasurementRequest.options = params["options"]
        mapMeasurementRequest.filter = params["filter"]
        
        // add highlight filter (my measurements filter)
        //mapMeasurementRequest.filter?["highlight"] = ControlServer.sharedControlServer.uuid

        // submit client_uuid to get measurement_uuid if tapped on an own measurement
        mapMeasurementRequest.clientUuid = ControlServer.sharedControlServer.uuid
        
        request(.POST, path: "/tiles/markers", requestObject: mapMeasurementRequest, success: { (response: MapMeasurementResponse) in
            if let measurements = response.measurements {
                successCallback(response: measurements)
            } else {
                failure(error: NSError(domain: "no measurements", code: -12543, userInfo: nil))
            }
        }, error: failure)
    }

    ///
    public func getTileUrlForMapOverlayType(overlayType: String, x: UInt, y: UInt, zoom: UInt, params: [String: AnyObject]?) -> NSURL? {
        if let base = baseUrl {
            // baseUrl and layer
            var urlString = base + "/tiles/\(overlayType)?path=\(zoom)/\(x)/\(y)"

            // add uuid for highlight
            if let uuid = ControlServer.sharedControlServer.uuid {
                urlString += "&highlight=\(uuid)"
            }

            // add params
            if let p = params where p.count > 0 {
                let paramString = p.map({ (key, value) in
                    let escapedKey = key.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())

                    var escapedValue: String?
                    if let v = value as? String {
                        escapedValue = v.stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet()) // TODO: does this need a cast to string?
                    }

                    return "\(escapedKey ?? key)=\(escapedValue ?? value)"
                }).joinWithSeparator("&")

                urlString += "&" + paramString
            }

            logger.debug("Generated tile url: \(urlString)")

            return NSURL(string: urlString)
        }

        return nil
    }

    ///
    public func getOpenTestUrl(openTestUuid: String, success successCallback: (response: String?) -> ()) {
        //ControlServer.sharedControlServer.openTest
        // TODO
        successCallback(response: nil)
    }

// MARK: Private

    ///
    private func opentestURLForApp(openTestBaseURL: String) -> String {
        // hardcoded because @lb doesn't want to provide a good solution

        let r = openTestBaseURL.startIndex..<openTestBaseURL.endIndex
        let appOpenTestBaseURL = openTestBaseURL.stringByReplacingOccurrencesOfString("/opentest", withString: "/app/opentest", options: NSStringCompareOptions.LiteralSearch, range: r)

        return appOpenTestBaseURL
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
