//
//  RMBTNominatim.swift
//  RMBTClient
//
//  Created by Sergey Glushchenko on 11/10/17.
//

import CoreLocation
import Alamofire

class RMBTNominatim: NSObject {
    
    private let nominatimUrl = "http://nominatim.openstreetmap.org/reverse"
    private let addressKey = "address"
    
    private func url(with location: CLLocation) -> String {
        let url = String(format: "%@?format=jsonv2&lat=%f&lon=%f", self.nominatimUrl, location.coordinate.latitude, location.coordinate.longitude)
        return url
        
    }
    func reverseGeocodeLocation(location: CLLocation, completionHandler: @escaping ((_ address: RMBTNominatimAddress?, _ error: Error?)-> Void)) {
        
        let url = self.url(with: location)
        AF.request(url).responseJSON { (response) in
            if let error = response.error {
                completionHandler(nil, error)
            }
            else {
                if let responseDictionary = response.value as? [String: Any],
                    let addressDictionary = responseDictionary[self.addressKey] as? [String: Any] {
                    let address = RMBTNominatimAddress(dictionary: addressDictionary)
                    completionHandler(address, response.error)
                }
                else {
                    completionHandler(nil, response.error)
                }
            }
        }
    }
}
