//
//  IPRequest.swift
//  Pods
//
//  Created by Tomas Baculák on 23/04/2017.
//
//

import UIKit
import ObjectMapper

class IPRequest: BasicRequest {
    
    ///
    var uuid: String?
    
    ///
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        uuid <- map["uuid"]
    }

}

class IPRequest_Old: BasicRequest_Old {
    
    ///
    var uuid: String?
    
    ///
    override func mapping(map: Map) {
        super.mapping(map: map)
        
        uuid <- map["uuid"]
    }
    
}
