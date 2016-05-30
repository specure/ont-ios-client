//
//  ConnectivityServiceDelegate.swift
//  RMBT
//
//  Created by Benjamin Pucher on 24.02.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
protocol ConnectivityServiceDelegate {

    ///
    func connectivityDidChange(connectivityService: ConnectivityService, connectivityInfo: ConnectivityInfo)
}
