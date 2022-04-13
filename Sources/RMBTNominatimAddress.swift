//
//  RMBTNominatimAddress.swift
//  RMBTClient
//
//  Created by Sergey Glushchenko on 11/10/17.
//

import ObjectMapper

class RMBTNominatimAddress: NSObject, Mappable {

    var neighbourhood: String?
    var road: String?
    var village: String?
    var stateDistrict: String?
    var state: String?
    var postcode: String?
    var country: String?
    var countryCode: String?
    var suburb: String?
    var cityDistrict: String?
    var city: String?
    var town: String?
    
    required init?(map: Map) {
        super.init()
        self.mapping(map: map)
    }
    
    convenience init?(dictionary: [String: Any]) {
        self.init(map: Map(mappingType: .fromJSON, JSON: dictionary))
    }
    
    func mapping(map: Map) {
        city            <- map["city"]
        town            <- map["town"]
        suburb          <- map["suburb"]
        neighbourhood   <- map["neighbourhood"]
        cityDistrict    <- map["city_district"]
        road            <- map["road"]
        village         <- map["village"]
        stateDistrict   <- map["state_district"]
        state           <- map["state"]
        postcode        <- map["postcode"]
        country         <- map["country"]
        countryCode     <- map["country_code"]
    }
    
    func cityDistrictAlias() -> String? {
        if suburb != nil {
            return suburb
        }
        if cityDistrict != nil {
            return cityDistrict
        }
        if neighbourhood != nil {
            return neighbourhood
        }
        
        return nil
    }
    
    func cityAlias() -> String? {
        if city != nil {
            return city
        }
        if town != nil {
            return town
        }
        
        return nil
    }
}
