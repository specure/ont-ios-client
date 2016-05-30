//
//  QOSControlConnectionDelegate.swift
//  RMBT
//
//  Created by Benjamin Pucher on 09.12.14.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

import Foundation

///
protocol QOSControlConnectionDelegate {

    ///
    func controlConnectionReadyToUse(connection: QOSControlConnection)
}
