//
//  AdvertisingResponse.swift
//  RMBTClient
//
//  Created by Sergey Glushchenko on 6/30/18.
//

import UIKit
import ObjectMapper

public class BadgeCriteriaTermResponse: BasicResponse {
    public var type: String?
    public var `operator`: String?
    public var value: String?
    
    override open func mapping(map: Map) {
        super.mapping(map: map)
        
        type <- map["type"]
        `operator` <- map["operator"]
        value <- map["value"]
    }
}

public class BadgeResponse: BasicResponse {
    public var identifier: String?
    public var title: String?
    public var descriptionText: String?
    public var category: String?
    public var image_link: String?
    public var terms_operator: String?
    public var criteria: [BadgeCriteriaTermResponse]?
    
    override open func mapping(map: Map) {
        super.mapping(map: map)
        
        identifier <- map["id"]
        title <- map["title"]
        descriptionText <- map["description"]
        category <- map["category"]
        image_link <- map["image_link"]
        terms_operator <- map["terms_operator"]
        criteria <- map["criteria"]
    }
}

public class BadgesResponse: BasicResponse {
    public var badges: [BadgeResponse] = []
    
    override open func mapping(map: Map) {
        super.mapping(map: map)
        
        badges <- map["badges"]
    }
}
