//
//  AdvertisingResponse.swift
//  RMBTClient
//
//  Created by Sergey Glushchenko on 6/30/18.
//

import UIKit
import ObjectMapper

public class AdvertisingResponse: BasicResponse {
    var isShowAdvertising: Bool = false
    var adProvider: String?
    var bannerId: String?
    var appId: String?
    
    override open func mapping(map: Map) {
        super.mapping(map: map)
        
        isShowAdvertising <- map["isShowAdvertising"]
        adProvider        <- map["adProvider"]
        bannerId          <- map["bannerId"]
        appId             <- map["appId"]
    }
}
