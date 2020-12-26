//
//  RMBTNominatimAddress.swift
//  RMBTClient
//
//  Created by Sergey Glushchenko on 11/10/17.
//

class RMBTNominatimAddress: NSObject {

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
    
    init(dictionary: [String: Any]) {
        if let city = dictionary["city"] as? String {
            self.city = city
        }
        
        if let town = dictionary["town"] as? String {
            self.town = town
        }
        
        if let suburb = dictionary["suburb"] as? String {
            self.suburb = suburb
        }
        
        if let neighbourhood = dictionary["neighbourhood"] as? String {
            self.neighbourhood = neighbourhood
        }
        
        if let cityDistrict = dictionary["city_district"] as? String {
            self.cityDistrict = cityDistrict
        }
        
        if let road = dictionary["road"] as? String {
            self.road = road
        }
        
        if let village = dictionary["village"] as? String {
            self.village = village
        }
        
        if let stateDistrict = dictionary["state_district"] as? String {
            self.stateDistrict = stateDistrict
        }
        
        if let state = dictionary["state"] as? String {
            self.state = state
        }
        
        if let postcode = dictionary["postcode"] as? String {
            self.postcode = postcode
        }
        
        if let country = dictionary["country"] as? String {
            self.country = country
        }
        
        if let countryCode = dictionary["country_code"] as? String {
            self.countryCode = countryCode
        }
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
