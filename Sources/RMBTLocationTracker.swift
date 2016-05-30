//
//  RMBTLocationTracker.swift
//  RMBT
//
//  Created by Benjamin Pucher on 19.09.14.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

import Foundation
import CoreLocation

///
let RMBTLocationTrackerNotification: String = "RMBTLocationTrackerNotification"

///
class RMBTLocationTracker: NSObject, CLLocationManagerDelegate {

    ///
    static let sharedTracker = RMBTLocationTracker()

    ///
    let locationManager: CLLocationManager

    ///
    var authorizationCallback: RMBTBlock?

    ///
    var location: CLLocation? {
        // TODO: if app is not allowed to get location this code fails! WORKS without ".copy() as? CLLocation", but are there any consequences?
        if let result: CLLocation = locationManager.location/*.copy() as? CLLocation*/ {
            if CLLocationCoordinate2DIsValid(result.coordinate) {
                return result
            }
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
    func stop() {
        locationManager.stopMonitoringSignificantLocationChanges()
        locationManager.stopUpdatingLocation()
    }

    ///
    func startIfAuthorized() -> Bool {
        let authorizationStatus = CLLocationManager.authorizationStatus()

        if authorizationStatus == .AuthorizedWhenInUse || authorizationStatus == .AuthorizedAlways {
            locationManager.startUpdatingLocation()
            return true
        }

        return false
    }

    ///
    func startAfterDeterminingAuthorizationStatus(callback: RMBTBlock) {
        if startIfAuthorized() {
            callback()
        } else if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.NotDetermined {
            // Not determined yet
            authorizationCallback = callback

            locationManager.requestWhenInUseAuthorization()
        } else {
            logger.warning("User hasn't enabled or authorized location services")
            callback()
        }
    }

    ///
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        NSNotificationCenter.defaultCenter().postNotificationName(RMBTLocationTrackerNotification, object: self, userInfo:["locations": locations])
    }

    ///
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if locationManager.respondsToSelector(#selector(CLLocationManager.startUpdatingLocation)) {
            locationManager.startUpdatingLocation()
        }

        if let authorizationCallback = self.authorizationCallback {
            authorizationCallback()
        }
    }

    ///
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        logger.error("Failed to obtain location \(error)")
    }

    ///
    func forceUpdate() {
        stop()
        startIfAuthorized()
    }
}
