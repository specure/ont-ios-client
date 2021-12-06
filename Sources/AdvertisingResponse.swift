//
//  AdvertisingResponse.swift
//  RMBTClient
//
//  Created by Sergey Glushchenko on 6/30/18.
//

import ObjectMapper

public class AdvertisingResponse: BasicResponse {
    public var isShowAdvertising: Bool = false
    public var adProvider: String?
    public var bannerId: String?
    public var appId: String?
    
    override open func mapping(map: Map) {
        super.mapping(map: map)
        
        isShowAdvertising <- map["isShowAdvertising"]
        adProvider        <- map["adProvider"]
        bannerId          <- map["bannerId"]
        appId             <- map["appId"]
    }
}
