/*****************************************************************************************************
 * Copyright 2013 appscape gmbh
 * Copyright 2014-2016 SPECURE GmbH
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *****************************************************************************************************/

import Foundation
import CoreLocation

///
public let RMBTLocationTrackerNotification = "RMBTLocationTrackerNotification"

///
open class RMBTLocationTracker: NSObject, CLLocationManagerDelegate {

    ///
    public static let sharedTracker = RMBTLocationTracker()

    ///
    public let locationManager: CLLocationManager

    ///
    open var authorizationCallback: EmptyCallback?
    
    ///
    open var location: CLLocation? {
        if let result = locationManager.location, CLLocationCoordinate2DIsValid(result.coordinate) {
            return result
        }

        return nil
    }

    ///
    override private init() {
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 3.0
        //locationManager.requestAlwaysAuthorization()

        super.init()

        locationManager.delegate = self
    }
    
    deinit {
        stop()
    }

    ///
    open func stop() {
        #if os(iOS) // TODO: replacement for this method?
        locationManager.stopMonitoringSignificantLocationChanges()
        #endif
        locationManager.stopUpdatingLocation()
    }

    ///
    open func startIfAuthorized() -> Bool {
        let authorizationStatus = CLLocationManager.authorizationStatus()

        #if os(OSX) // TODO
        #else
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            #if os(iOS) // TODO: replacement for this method?
            locationManager.startUpdatingLocation()
            #endif
            return true
        }
        #endif

        return false
    }

    ///
    open func startAfterDeterminingAuthorizationStatus(_ callback: @escaping EmptyCallback) {
        if startIfAuthorized() {
            callback()
        } else if CLLocationManager.authorizationStatus() == .notDetermined {
            // Not determined yet
            authorizationCallback = callback

            #if os(OSX) // TODO
            #else
            locationManager.requestWhenInUseAuthorization()
            #endif
        } else {
            Log.logger.warning("User hasn't enabled or authorized location services")
            callback()
        }
    }

    #if os(OSX) // TODO
    #else

    ///
    open func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        NotificationCenter.default.post(name: Notification.Name(rawValue: RMBTLocationTrackerNotification),
                                        object: self,
                                        userInfo:["locations": locations])
    }

    #endif

    ///
    open func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        #if os(iOS) // TODO: replacement for this method?
        if locationManager.responds(to: #selector(CLLocationManager.startUpdatingLocation)) {
            locationManager.startUpdatingLocation()
        }
        #endif

        if let authorizationCallback = self.authorizationCallback {
            authorizationCallback()
        }
    }

    ///
    open func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Log.logger.error("Failed to obtain location \(error)")
    }

    ///
    open func forceUpdate() {
        stop()
        _ = startIfAuthorized()
    }
    
    open func isLocationManagerEnabled() -> Bool {
        return CLLocationManager.authorizationStatus() == .authorizedAlways || CLLocationManager.authorizationStatus() == .authorizedWhenInUse
    }
}

extension CLLocation {
    ///
    open func fetchCountryAndCity(completion: @escaping (String?, String?) -> ()) {
        RMBTNominatim().reverseGeocodeLocation(location: self) {
            address, error in
            if let error = error {
                print(error)
                completion(nil, nil)
            }
            else {
                let country = address?.countryCode
                var city = address?.cityDistrictAlias()
                if let cityResult = city,
                    let cityAlias = address?.cityAlias() {
                    city = cityResult + ", " + cityAlias
                }
                else {
                    if let cityAlias = address?.cityAlias() {
                        city = cityAlias
                    }
                }
                completion(country, city)
            }
        }
//        CLGeocoder().reverseGeocodeLocation(self) { placemarks, error in
//            if let error = error {
//                print(error)
//                completion(nil, nil)
//            } else if let country = placemarks?.first?.isoCountryCode,
//                let city = placemarks?.first?.locality {
//                completion(country, city)
//            }
//        }
    }
}
