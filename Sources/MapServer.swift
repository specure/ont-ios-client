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
    public func getMapOptions(success successCallback: EmptyCallback, error failure: ErrorCallback) {
        request(.POST, path: "/tiles/info", requestObject: BasicRequest(), success: { response in

            // TODO: return map options

        }, error: failure)
    }

    ///
    public func getMeasurementsAtCoordinate(coordinate: CLLocationCoordinate2D, zoom: Int, success successCallback: EmptyCallback, error failure: ErrorCallback) {
        // TODO
    }

    //public func tileURLForMapOverlayType(overlayType: String, x: UInt, y: UInt, zoom: UInt, params: NSDictionary) -> NSURL {
    //
    //}

    ///
    public func getOpenTestUrl(openTestUuid: String, success successCallback: EmptyCallback) {
        // TODO
    }

// MARK: Private

    ///
    private func opentestURLForApp(openTestBaseURL: String) -> String {
        return "TODO"
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
