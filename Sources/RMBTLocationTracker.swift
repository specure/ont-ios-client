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
