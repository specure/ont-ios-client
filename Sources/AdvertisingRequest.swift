//
//  AdvertisingRequest.swift
//  RMBTClient
//
//  Created by Sergey Glushchenko on 6/30/18.
//

import UIKit
import ObjectMapper

class AdvertisingRequest: BasicRequest {
    
    var country: String? = ((NSLocale.current as NSLocale).object(forKey: NSLocale.Key.countryCode) as? String)?.lowercased()
    
    ///
    public override func mapping(map: Map) {
        //
        uuid            <- map["uuid"]
        country         <- map["country"]
    }
}
