//
//  BasicRequestBuilder_OSX.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 31.05.16.
//
//

import Foundation

///
class BasicRequestBuilder: AbstractBasicRequestBuilder {

    ///
    override class func addBasicRequestValues(basicRequest: BasicRequest) {
        super.addBasicRequestValues(basicRequest)

        basicRequest.device = "DESKTOP" //currentDevice.model
        basicRequest.model = "??" //UIDeviceHardware.platform()
        basicRequest.osVersion = "10.11" //currentDevice.systemVersion
        basicRequest.platform = "OSX"
        basicRequest.clientType = "DESKTOP"
    }

}
