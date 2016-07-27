//
//  RMBTMapMeasurement.swift
//  RMBT
//
//  Created by Benjamin Pucher on 30.03.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation
import CoreLocation

///
public class RMBTMapMeasurement {

    ///
    public var coordinate: CLLocationCoordinate2D

    ///
    public var timeString: String

    ///
    public var openTestUUID: String

    /// Arrays of RMBTHistoryResultItem
    public var netItems = [RMBTHistoryResultItem]()

    ///
    public var measurementItems = [RMBTHistoryResultItem]()

    ///
    public init(response: [String: AnyObject]) {
        let lat = response["lat"] as! NSNumber
        let lon = response["lon"] as! NSNumber

        coordinate = CLLocationCoordinate2DMake(lat.doubleValue, lon.doubleValue)

        timeString = response["time_string"] as! String
        openTestUUID = response["open_test_uuid"] as! String

        // TODO: new control server rewrite!
        /*let responseMeasurement = response["measurement"] as! [[String: AnyObject]]
        for subresponse in responseMeasurement {
            measurementItems.append(RMBTHistoryResultItem(response: subresponse))
        }

        let responseNet = response["net"] as! [[String: AnyObject]]
        for subresponse in responseNet {
            netItems.append(RMBTHistoryResultItem(response: subresponse))
        }*/
    }

    ///
    public func snippetText() -> String {
        let result: NSMutableString = ""

        /*for i in measurementItems {
            //result.appendFormat("%@: %@\n", i.title, i.value) // TODO: new control server rewrite!
        }

        for i in netItems {
            //result.appendFormat("%@: %@\n", i.title, i.value) // TODO: new control server rewrite!
        }*/

        return result as String
    }

}

///
extension RMBTMapMeasurement: CustomStringConvertible {

    ///
    public var description: String {
        return String(format: "RMBTMapMarker (%f, %f)", coordinate.latitude, coordinate.longitude)
    }
}
