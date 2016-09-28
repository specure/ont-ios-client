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
public class RMBTLocationTracker: NSObject, CLLocationManagerDelegate {

    ///
    public static let sharedTracker = RMBTLocationTracker()

    ///
    public let locationManager: CLLocationManager

    ///
    public var authorizationCallback: EmptyCallback?

    ///
    public var location: CLLocation? {
        if let result = locationManager.location where CLLocationCoordinate2DIsValid(result.coordinate) {
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

    ///
    public func stop() {
        #if os(iOS) // TODO: replacement for this method?
        locationManager.stopMonitoringSignificantLocationChanges()
        #endif
        locationManager.stopUpdatingLocation()
    }

    ///
    public func startIfAuthorized() -> Bool {
        let authorizationStatus = CLLocationManager.authorizationStatus()

        #if os(OSX) // TODO
        #else
        if authorizationStatus == .AuthorizedWhenInUse || authorizationStatus == .AuthorizedAlways {
            #if os(iOS) // TODO: replacement for this method?
            locationManager.startUpdatingLocation()
            #endif
            return true
        }
        #endif

        return false
    }

    ///
    public func startAfterDeterminingAuthorizationStatus(callback: EmptyCallback) {
        if startIfAuthorized() {
            callback()
        } else if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.NotDetermined {
            // Not determined yet
            authorizationCallback = callback

            #if os(OSX) // TODO
            #else
            locationManager.requestWhenInUseAuthorization()
            #endif
        } else {
            logger.warning("User hasn't enabled or authorized location services")
            callback()
        }
    }

    #if os(OSX) // TODO
    #else

    ///
    public func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        NSNotificationCenter.defaultCenter().postNotificationName(RMBTLocationTrackerNotification, object: self, userInfo:["locations": locations])
    }

    #endif

    ///
    public func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        #if os(iOS) // TODO: replacement for this method?
        if locationManager.respondsToSelector(#selector(CLLocationManager.startUpdatingLocation)) {
            locationManager.startUpdatingLocation()
        }
        #endif

        if let authorizationCallback = self.authorizationCallback {
            authorizationCallback()
        }
    }

    ///
    public func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        logger.error("Failed to obtain location \(error)")
    }

    ///
    public func forceUpdate() {
        stop()
        startIfAuthorized()
    }
}
