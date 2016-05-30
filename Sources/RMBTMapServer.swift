//
//  RMBTMapServer.swift
//  RMBT
//
//  Created by Benjamin Pucher on 30.03.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation
import AFNetworking
import CoreLocation

///
class RMBTMapServer {

    ///
    private var manager: AFHTTPRequestOperationManager!

    //

    ///
    init() {
        let mapServerURL = ControlServer.sharedControlServer.mapServerURL

        manager = AFHTTPRequestOperationManager(baseURL: mapServerURL)

        manager.requestSerializer = AFJSONRequestSerializer()
        manager.responseSerializer = AFJSONResponseSerializer()
    }

    ///
    func getMapOptionsWithSuccess(success: SuccessCallback) {
        self.requestWithMethod("POST", path: "tiles/info", params: nil, success: { response in

            let mapOptions = RMBTMapOptions(response: response as! [String:AnyObject])
            success(response: mapOptions)

        }, error: { error, info in
            logger.debug("Error \(error) \(info)")
        })
    }

    ///
    func getMeasurementsAtCoordinate(coordinate: CLLocationCoordinate2D, zoom: Float, params: NSDictionary, success: SuccessCallback) {
        //logger.debug(String(format: "Getting measurements at coordinate %f, %f, zoom: %f", coordinate.latitude, coordinate.longitude, zoom))

        let finalParams = NSMutableDictionary(dictionary: params)

        // Note: Android App has a hardcoded size of 20 with a todo notice "correct params (zoom, size)". We doubled the value for retina tiles.
        finalParams.addEntriesFromDictionary([
            "coords": [
                "lat":  NSNumber(double: coordinate.latitude),
                "lon":  NSNumber(double: coordinate.longitude),
                "z":    NSNumber(unsignedInteger: UInt(zoom))
            ] as [String: NSNumber],
            "size": "40"
        ])

        //

        self.requestWithMethod("POST", path: "tiles/markers", params: finalParams, success: { response in

            var measurements = [RMBTMapMeasurement]()

            for subresponse in (response["measurements"] as! [[String:AnyObject]]) {
                measurements.append(RMBTMapMeasurement(response: subresponse))
            }

            logger.debug("Got \(measurements.count) measurements")
            logger.debug("measurements: \(measurements)")

            success(response: measurements)

        }, error: { error, info in
            logger.debug("Error \(error) \(info)")
        })
    }

    ///
    func tileURLForMapOverlayType(overlayType: String, x: UInt, y: UInt, zoom: UInt, params: NSDictionary) -> NSURL {
        let urlString: NSMutableString = NSMutableString(string: manager.baseURL.absoluteString)

        urlString.appendFormat("tiles/%@?path=%lu/%lu/%lu&", overlayType, zoom, x, y)
        urlString.appendString(RMBTQueryStringFromDictionary(params as [NSObject : AnyObject]))

        if let uuid = ControlServer.sharedControlServer.uuid {
            urlString.appendFormat("&%@", RMBTQueryStringFromDictionary(["highlight": uuid]))
        }

        return NSURL(string: urlString as String)!
    }

    ///
    func getURLStringForOpenTestUUID(openTestUUID: String, success: SuccessCallback) {
        let sharedControlServer = ControlServer.sharedControlServer

        if let openTestBaseURL = sharedControlServer.openTestBaseURL {
            success(response: /*opentestURLForApp(*/openTestBaseURL/*)*/.stringByAppendingString(openTestUUID))
        } else {
            sharedControlServer.getSettings({
                if let openTestBaseURL = sharedControlServer.openTestBaseURL {
                    success(response: /*self.opentestURLForApp(*/openTestBaseURL/*)*/.stringByAppendingString(openTestUUID))
                } else {
                    success(response: "nil") // TODO: nil as argument type?
                }
            }, error: { error, info in
                // TODO: handle error
            })
        }
    }

    ///
//    private func opentestURLForApp(openTestBaseURL: String) -> String {
//        // hardcoded because @lb doesn't want to provide a good solution
//
//        let r = Range<String.Index>(start: openTestBaseURL.startIndex, end: openTestBaseURL.endIndex)
//        let appOpenTestBaseURL = openTestBaseURL.stringByReplacingOccurrencesOfString("/opentest", withString: "/app/opentest", options: NSStringCompareOptions.LiteralSearch, range: r)
//
//        return appOpenTestBaseURL
//    }

    /// TODO: this method has a lot code in common with ControlServer
    private func requestWithMethod(method: String, path: String, params: NSDictionary?, success: SuccessCallback, error failure: ErrorCallback) {
        let mergedParams = NSMutableDictionary()

        mergedParams["language"] = RMBTValueOrNull(RMBTPreferredLanguage()) // TODO: change

        if let p = params {
            mergedParams.addEntriesFromDictionary(p as [NSObject : AnyObject])
        }

        ////

        let urlString: String = manager.baseURL.absoluteString.stringByAppendingString(path)

        let request: NSMutableURLRequest? = try? self.manager.requestSerializer.requestWithMethod(method, URLString: urlString, parameters: mergedParams, error: ())

        let operation = manager.HTTPRequestOperationWithRequest(request, success: { (operation: AFHTTPRequestOperation!, responseObject: AnyObject!) in

            // TODO: improve
            if operation.response.statusCode < 400 {
                success(response: responseObject as! NSObject)
            } else {
                let error = NSError(domain: "error_", code: 123, userInfo: nil)
                failure(error: error, info: nil)
            }

        }, failure: { (operation: AFHTTPRequestOperation!, error: NSError!) in

            if error != nil && error.code == Int(CFNetworkErrors.CFURLErrorCancelled.rawValue) {
                return  // Ignore cancelled requests
            }

            failure(error: error, info: nil/*operation.responseString*/) // TODO: no response object?
        })

        operation.start()
    }

    ///
    private func RMBTEscapeString(input: AnyObject) -> String { // TODO: change
        if let str = input as? String {
            let customAllowedSet =  NSCharacterSet(charactersInString: "!*'\"();:@&=+$,/?%#[]% ").invertedSet
            let escapedString = str.stringByAddingPercentEncodingWithAllowedCharacters(customAllowedSet)

            return escapedString!
        }

        return ""
    }

    ///
    private func RMBTQueryStringFromDictionary(input: [NSObject:AnyObject]) -> String { // TODO: change
        var params = [String]() // capacity: input.count

        for key in input.keys {
            params.append(String(format: "%@=%@", RMBTEscapeString(key), RMBTEscapeString(input[key]!)))
        }

        return params.joinWithSeparator("&")
        //return (params as NSArray).componentsJoinedByString("&")
        //return [params componentsJoinedByString:@"&"];
    }
}
