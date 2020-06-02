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

#if os(tvOS)
// TODO
#else
import CoreTelephony
import GCNetworkReachability
#endif // TODO: use library for network reachability that works on tvOS

///
@objc public protocol RMBTConnectivityTrackerDelegate {

    //    var currentConnectivityNetworkType: RMBTNetworkType? { @objc(currentConnectivityNetworkType)get @objc(setCurrentConnectivityNetworkType:)set }
    func connectivityNetworkTypeDidChange(connectivity: RMBTConnectivity)
    
    ///
    func connectivityTracker(_ tracker: RMBTConnectivityTracker, didDetectConnectivity connectivity: RMBTConnectivity)

    ///
    func connectivityTracker(_ tracker: RMBTConnectivityTracker, didStopAndDetectIncompatibleConnectivity connectivity: RMBTConnectivity)

    ///
    func connectivityTrackerDidDetectNoConnectivity(_ tracker: RMBTConnectivityTracker)
}

///
open class RMBTConnectivityTracker: NSObject {

    private static var __once: () = {
            #if os(iOS)
            RMBTConnectivityTracker.sharedReachability.startMonitoringNetworkReachabilityWithNotification()
            #endif
        }()

    #if os(iOS)

    /// GCNetworkReachability is not made to be multiply instantiated, so we create a global
    /// singleton first time a RMBTConnectivityTracker is instatiated
    private static var sharedReachability: GCNetworkReachability = GCNetworkReachability.forInternetConnection()

    /// According to http://www.objc.io/issue-5/iOS7-hidden-gems-and-workarounds.html one should
    /// keep a reference to CTTelephonyNetworkInfo live if we want to receive radio changed notifications (?)
    private static let sharedNetworkInfo: CTTelephonyNetworkInfo = CTTelephonyNetworkInfo()

    #endif

    ///
    private let queue = DispatchQueue(label: "com.specure.nettest.connectivitytracker", attributes: [])

    ///
    private weak var delegate: RMBTConnectivityTrackerDelegate?

    ///
    private var lastConnectivity: RMBTConnectivity? {
        didSet {
            print("lastConnectivity changed")
        }
    }

    ///
    private var stopOnMixed = false

    ///
    private var started = false

    ///
    private var lastRadioAccessTechnology: String?

    ///
    struct Static {
        static var token: Int = 0
    }

    private let refreshTimeinterval = 1.0
    private var refreshTimer: Timer? { //Hack. Sometimes we don't have changes from reachability
        didSet {
            if let timer = oldValue,
                timer.isValid == true {
                timer.invalidate()
            }
        }
    }
    ///
    public init(delegate: RMBTConnectivityTrackerDelegate, stopOnMixed: Bool) {
        self.delegate = delegate
        self.stopOnMixed = stopOnMixed

        #if os(iOS)
        _ = RMBTConnectivityTracker.__once
        #endif
    }

    ///
    @objc open func appWillEnterForeground(_ notification: Notification) {
        queue.async {
            // Restart various observartions and force update (if already started)
            if self.started {
                self.start()
            }
        }
    }

    @objc func refreshTimerHandler(_ timer: Timer) {
        #if os(iOS)
        if let reachability = GCNetworkReachability.forInternetConnection(),
            reachability.currentReachabilityStatus() != RMBTConnectivityTracker.sharedReachability.currentReachabilityStatus() {
            RMBTConnectivityTracker.sharedReachability = reachability
            
            reachability.startMonitoringNetworkReachabilityWithNotification()
            let status = RMBTConnectivityTracker.sharedReachability.currentReachabilityStatus()
            self.reachabilityDidChangeToStatus(status)
        }
        #endif
    }
    
    ///
    open func start() {
        DispatchQueue.main.async {
            self.refreshTimer = Timer.scheduledTimer(timeInterval: self.refreshTimeinterval, target: self, selector: #selector(self.refreshTimerHandler(_:)), userInfo: nil, repeats: true)
        }
        queue.async {
            self.started = true
            self.lastRadioAccessTechnology = nil

            // Re-Register for notifications
            NotificationCenter.default.removeObserver(self)

            #if os(iOS)
            NotificationCenter.default.addObserver(self, selector: #selector(RMBTConnectivityTracker.appWillEnterForeground(_:)),
                                                   name: UIApplication.willEnterForegroundNotification, object: nil)

            NotificationCenter.default.addObserver(self, selector: #selector(RMBTConnectivityTracker.reachabilityDidChange(_:)),
                                                             name: NSNotification.Name.gcNetworkReachabilityDidChange, object: nil)

            NotificationCenter.default.addObserver(self, selector: #selector(RMBTConnectivityTracker.radioDidChange(_:)),
                                                             name: NSNotification.Name.CTRadioAccessTechnologyDidChange, object: nil)

            self.reachabilityDidChangeToStatus(RMBTConnectivityTracker.sharedReachability.currentReachabilityStatus())
            #endif
        }
    }

    ///
    open func stop() {
        queue.async {
            self.refreshTimer = nil
            NotificationCenter.default.removeObserver(self)

            self.started = false
        }
    }

    ///
    open func forceUpdate() {
        queue.async {
            #if os(iOS)
            assert(self.lastConnectivity != nil, "Connectivity should be known by now")
            guard let connectivity = self.lastConnectivity else { return }
            self.delegate?.connectivityTracker(self, didDetectConnectivity: connectivity)
            #endif
        }
    }

    ///
    @objc open func reachabilityDidChange(_ n: Notification) {
        #if os(iOS)
        if let status = n.userInfo?[kGCNetworkReachabilityStatusKey] as? NSNumber {
            queue.async {
                self.reachabilityDidChangeToStatus(GCNetworkReachabilityStatus.init(status.uint8Value))
            }
        }
        #endif
    }

    ///
    @objc open func radioDidChange(_ n: Notification) {
        queue.async {
            // Note:Sometimes iOS delivers multiple notification w/o radio technology actually changing
            if (n.object as? String) == self.lastRadioAccessTechnology {
                return
            }

            self.lastRadioAccessTechnology = n.object as? String

            #if os(iOS)
            self.reachabilityDidChangeToStatus(RMBTConnectivityTracker.sharedReachability.currentReachabilityStatus())
            #endif
        }
    }

    #if os(iOS)

    ///
    private func reachabilityDidChangeToStatus(_ status: GCNetworkReachabilityStatus) {
        let networkType: RMBTNetworkType

        if status == GCNetworkReachabilityStatusNotReachable {
            networkType = .none
        } else if status == GCNetworkReachabilityStatusWiFi {
            networkType = .wiFi
        } else if status == GCNetworkReachabilityStatusWWAN {
            networkType = .cellular
        } else {
            Log.logger.debug("Unknown reachability status \(status)")
            return
        }

        if networkType == .none {
            Log.logger.debug("No connectivity detected.")

            lastConnectivity = nil

            delegate?.connectivityTrackerDidDetectNoConnectivity(self)

            return
        }

        let connectivity = RMBTConnectivity(networkType: networkType)

        if connectivity.isEqualToConnectivity(lastConnectivity) {
            return
        }

        Log.logger.debug("New connectivity = \(connectivity)")
        
        if let lastConnection = self.lastConnectivity,
            lastConnection.networkType != .none {
            DispatchQueue.main.async {
                self.delegate?.connectivityNetworkTypeDidChange(connectivity: lastConnection)
            }
            
        }
        
        if stopOnMixed {
            // Detect compatilibity
            var compatible = true

            if lastConnectivity != nil {
                if connectivity.networkType != lastConnectivity?.networkType {
                    Log.logger.debug("Connectivity network mismatched \(self.lastConnectivity?.networkTypeDescription ?? "unkowed") -> \(connectivity.networkTypeDescription)")

                    compatible = false
                } else if connectivity.networkName != lastConnectivity?.networkName {
                    Log.logger.debug("Connectivity network name mismatched \(self.lastConnectivity?.networkName ?? "unkowed") -> \(connectivity.networkName ?? "")")
                    compatible = false
                }
            }

            lastConnectivity = connectivity

            if compatible {
                delegate?.connectivityTracker(self, didDetectConnectivity: connectivity)
            } else {
                // stop
                stop()

                delegate?.connectivityTracker(self, didStopAndDetectIncompatibleConnectivity: connectivity)
            }
        } else {
            lastConnectivity = connectivity
            delegate?.connectivityTracker(self, didDetectConnectivity: connectivity)
        }
    }

    #endif

    ///
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
