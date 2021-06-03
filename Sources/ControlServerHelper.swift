//
//  ControlServerHelper.swift
//  RMBTClient
//
//  Created by Sergey Glushchenko on 7/1/19.
//

internal class ControlServerHelper: NSObject {
    internal func requestSpeedMeasurement(completionHandler: @escaping (_ response: SpeedMeasurementResponse?, _ error: Error?) -> Void) {
        ////////////////
        
        let speedMeasurementRequest = SpeedMeasurementRequest()
        
        speedMeasurementRequest.version = "0.3" // TODO: duplicate?
        speedMeasurementRequest.time = UInt64.currentTimeMillis()
        
        speedMeasurementRequest.testCounter = RMBTSettings.sharedSettings.testCounter
        
        if let l = RMBTLocationTracker.sharedTracker.location {
            let geoLocation = GeoLocation(location: l)
            speedMeasurementRequest.geoLocation = geoLocation
        }
        
        let controlServer = ControlServer.sharedControlServer
        
        /////!!!!!!!!!!!
        if RMBTConfig.sharedInstance.RMBT_VERSION_NEW {
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
            
            if let l = RMBTLocationTracker.sharedTracker.location {
                let geoLocation = GeoLocation(location: l)
                
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
