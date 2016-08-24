//
//  RMBTConnectivityTracker.swift
//  RMBT
//
//  Created by Benjamin Pucher on 17.09.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

#if os(tvOS)
// TODO
#else
import CoreTelephony
import GCNetworkReachability
#endif // TODO: use library for network reachability that works on tvOS

///
public protocol RMBTConnectivityTrackerDelegate {

    ///
    func connectivityTracker(tracker: RMBTConnectivityTracker, didDetectConnectivity connectivity: RMBTConnectivity)

    ///
    func connectivityTracker(tracker: RMBTConnectivityTracker, didStopAndDetectIncompatibleConnectivity connectivity: RMBTConnectivity)

    ///
    func connectivityTrackerDidDetectNoConnectivity(tracker: RMBTConnectivityTracker)
}

///
public class RMBTConnectivityTracker: NSObject {

    #if os(iOS)

    /// GCNetworkReachability is not made to be multiply instantiated, so we create a global
    /// singleton first time a RMBTConnectivityTracker is instatiated
    private static let sharedReachability: GCNetworkReachability = GCNetworkReachability.reachabilityForInternetConnection()

    /// According to http://www.objc.io/issue-5/iOS7-hidden-gems-and-workarounds.html one should
    /// keep a reference to CTTelephonyNetworkInfo live if we want to receive radio changed notifications (?)
    private static let sharedNetworkInfo: CTTelephonyNetworkInfo = CTTelephonyNetworkInfo()

    #endif
    
    ///
    private let queue = dispatch_queue_create("com.specure.nettest.connectivitytracker", DISPATCH_QUEUE_SERIAL)

    ///
    private let delegate: RMBTConnectivityTrackerDelegate

    ///
    private var lastConnectivity: RMBTConnectivity!

    ///
    private var stopOnMixed = false

    ///
    private var started = false

    ///
    private var lastRadioAccessTechnology: String!

    ///
    struct Static {
        static var token: dispatch_once_t = 0
    }

    ///
    public init(delegate: RMBTConnectivityTrackerDelegate, stopOnMixed: Bool) {
        self.delegate = delegate
        self.stopOnMixed = stopOnMixed

        #if os(iOS)
        dispatch_once(&Static.token) {
            RMBTConnectivityTracker.sharedReachability.startMonitoringNetworkReachabilityWithNotification()
        }
        #endif
    }

    ///
    public func appWillEnterForeground(notification: NSNotification) {
        dispatch_async(queue) {
            // Restart various observartions and force update (if already started)
            if self.started {
                self.start()
            }
        }
    }

    ///
    public func start() {
        dispatch_async(queue) {
            self.started = true
            self.lastRadioAccessTechnology = nil

            // Re-Register for notifications
            NSNotificationCenter.defaultCenter().removeObserver(self)

            #if os(iOS)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(RMBTConnectivityTracker.appWillEnterForeground(_:)),
                                                             name: UIApplicationWillEnterForegroundNotification, object: nil)

            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(RMBTConnectivityTracker.reachabilityDidChange(_:)),
                                                             name: kGCNetworkReachabilityDidChangeNotification, object: nil)

            NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(RMBTConnectivityTracker.radioDidChange(_:)),
                                                             name: CTRadioAccessTechnologyDidChangeNotification, object: nil)

            self.reachabilityDidChangeToStatus(RMBTConnectivityTracker.sharedReachability.currentReachabilityStatus())
            #endif
        }
    }

    ///
    public func stop() {
        dispatch_async(queue) {
            NSNotificationCenter.defaultCenter().removeObserver(self)

            self.started = false
        }
    }

    ///
    public func forceUpdate() {
        dispatch_async(queue) {
            #if os(iOS)
            assert(self.lastConnectivity != nil, "Connectivity should be known by now")
            self.delegate.connectivityTracker(self, didDetectConnectivity: self.lastConnectivity)
            #endif
        }
    }

    ///
    public func reachabilityDidChange(n: NSNotification) {
        #if os(iOS)
        if let status = n.userInfo?[kGCNetworkReachabilityStatusKey] as? NSNumber {
            dispatch_async(queue) {
                self.reachabilityDidChangeToStatus(GCNetworkReachabilityStatus.init(status.unsignedCharValue))
            }
        }
        #endif
    }

    ///
    public func radioDidChange(n: NSNotification) {
        dispatch_async(queue) {
            // Note:Sometimes iOS delivers multiple notification w/o radio technology actually changing
            if (n.object as? String) == self.lastRadioAccessTechnology {
                return
            }

            self.lastRadioAccessTechnology = n.object as! String

            #if os(iOS)
            self.reachabilityDidChangeToStatus(RMBTConnectivityTracker.sharedReachability.currentReachabilityStatus())
            #endif
        }
    }

    #if os(iOS)

    ///
    private func reachabilityDidChangeToStatus(status: GCNetworkReachabilityStatus) {
        let networkType: RMBTNetworkType

        if status == GCNetworkReachabilityStatusNotReachable {
            networkType = .None
        } else if status == GCNetworkReachabilityStatusWiFi {
            networkType = .WiFi
        } else if status == GCNetworkReachabilityStatusWWAN {
            networkType = .Cellular
        } else {
            logger.debug("Unknown reachability status \(status)")
            return
        }

        if networkType == .None {
            logger.debug("No connectivity detected.")

            lastConnectivity = nil

            delegate.connectivityTrackerDidDetectNoConnectivity(self)

            return
        }

        let connectivity = RMBTConnectivity(networkType: networkType)

        if connectivity.isEqualToConnectivity(lastConnectivity) {
            return
        }

        logger.debug("New connectivity = \(connectivity)")

        if stopOnMixed {
            // Detect compatilibity
            var compatible = true

            if lastConnectivity != nil {
                if connectivity.networkType != lastConnectivity.networkType {
                    logger.debug("Connectivity network mismatched \(self.lastConnectivity.networkTypeDescription) -> \(connectivity.networkTypeDescription)")
                    compatible = false
                } else if connectivity.networkName != lastConnectivity.networkName {
                    logger.debug("Connectivity network name mismatched \(self.lastConnectivity.networkName) -> \(connectivity.networkName)")
                    compatible = false
                }
            }

            lastConnectivity = connectivity

            if compatible {
                delegate.connectivityTracker(self, didDetectConnectivity: connectivity)
            } else {
                // stop
                stop()

                delegate.connectivityTracker(self, didStopAndDetectIncompatibleConnectivity: connectivity)
            }
        } else {
            lastConnectivity = connectivity
            delegate.connectivityTracker(self, didDetectConnectivity: connectivity)
        }
    }

    #endif

    ///
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}
