//
//  BasicRequestBuilder.swift
//  rmbt-ios-client
//
//  Created by Benjamin Pucher on 31.05.16.
//
//

import Foundation

///
class AbstractBasicRequestBuilder {

    ///
    class func addBasicRequestValues(basicRequest: BasicRequest) {
        let infoDictionary = NSBundle.mainBundle().infoDictionary! // !

        basicRequest.apiLevel = nil // always null on iOS...
        basicRequest.clientName = "RMBT"
        basicRequest.language = RMBTPreferredLanguage()
        basicRequest.product = nil // always null on iOS...
        basicRequest.previousTestStatus = "TODO" // TODO: from settings
        basicRequest.softwareRevision = RMBTBuildInfoString()
        basicRequest.softwareVersion = infoDictionary["CFBundleShortVersionString"] as? String
        basicRequest.softwareVersionCode = infoDictionary["CFBundleVersion"] as? Int
        basicRequest.softwareVersionName = "0.3" // ??

        basicRequest.clientVersion = "0.3" // TODO: fix this on server side

        basicRequest.timezone = NSTimeZone.systemTimeZone().name
    }

}
