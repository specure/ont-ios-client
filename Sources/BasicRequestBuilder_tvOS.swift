//
//  BasicRequestBuilder_OSX.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 31.05.16.
//
//

import Foundation
import UIKit

///
class BasicRequestBuilder: AbstractBasicRequestBuilder {

    ///
    override class func addBasicRequestValues(basicRequest: BasicRequest) {
        super.addBasicRequestValues(basicRequest)

        let currentDevice = UIDevice.currentDevice()

        basicRequest.device = currentDevice.model
        basicRequest.model = UIDeviceHardware.platform()
        basicRequest.osVersion = currentDevice.systemVersion
        basicRequest.platform = "tvOS"
        basicRequest.clientType = "DESKTOP"//"APPLETV" // TODO: allow client type "APPLETV"
    }

}
