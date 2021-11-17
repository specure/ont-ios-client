//
//  ControlServerHelper.swift
//  RMBTClient
//
//  Created by Sergey Glushchenko on 7/1/19.
//

import CoreLocation

internal class ControlServerHelper: NSObject {
    internal func requestSpeedMeasurement(completionHandler: @escaping (_ response: SpeedMeasurementResponse?, _ error: Error?) -> Void) {
        if let l = RMBTLocationTracker.sharedTracker.location {
            let location = GeoLocation(location: l)
            let geocoder = CLGeocoder()
            
            geocoder.reverseGeocodeLocation(l) { [unowned self] placemarks, error in
                if let error = error {
                    print("RMBTTestRunner.reverseGeocodeLocation: \(error)")
                } else if let placemarks = placemarks, placemarks.count > 0  {
                    location.postalCode = placemarks[0].postalCode
                    location.city = placemarks[0].locality
                }
                self.requestWithLocation(location, completionHandler: completionHandler)
            }
        } else {
            requestWithLocation(nil, completionHandler: completionHandler)
        }
    }
    
    private func requestWithLocation(_ location: GeoLocation?, completionHandler: @escaping (_ response: SpeedMeasurementResponse?, _ error: Error?) -> Void) {
        let controlServer = ControlServer.sharedControlServer
        if RMBTConfig.sharedInstance.RMBT_VERSION_NEW {
            let speedMeasurementRequest = SpeedMeasurementRequest()
            
            speedMeasurementRequest.version = "0.3" // TODO: duplicate?
            speedMeasurementRequest.time = UInt64.currentTimeMillis()
            
            speedMeasurementRequest.testCounter = RMBTSettings.sharedSettings.testCounter
            
            if let geoLocation = location {
                speedMeasurementRequest.geoLocation = geoLocation
            }

            controlServer.requestSpeedMeasurement(speedMeasurementRequest, success: { response in
                completionHandler(response, nil)
            }) { error in
                completionHandler(nil, error)
            }
        } else {
            let speedMeasurementRequestOld = SpeedMeasurementRequest_Old()
            speedMeasurementRequestOld.testCounter = RMBTSettings.sharedSettings.testCounter
            //
            if let serverId = RMBTConfig.sharedInstance.measurementServer?.id as? UInt64 {
                speedMeasurementRequestOld.measurementServerId = serverId
            } else {
                // If Empty fiels id server -> sets defaults
                // speedMeasurementRequestOld.measurementServerId = RMBTConfig.sharedInstance.defaultMeasurementServerId
            }
            
            if let geoLocation = location {
                speedMeasurementRequestOld.geoLocation = geoLocation
            }
            
            // workaround - nasty :(
            controlServer.requestSpeedMeasurement_Old(speedMeasurementRequestOld, success: { response in
                let r = response.toSpeedMeasurementResponse()
                completionHandler(r, nil)
            }) { error in
                completionHandler(nil, error)
            }
        }
    }
}
