//
//  QOSTestExecutorProtocol.swift
//  RMBT
//
//  Created by Benjamin Pucher on 05.12.14.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

import Foundation

///
protocol QOSTestExecutorProtocol {

    ///
    func execute(finish finishCallback: (testResult: QOSTestResult) -> ())

    ///
    func needsControlConnection() -> Bool

    ///
    func needsCustomTimeoutHandling() -> Bool

    ///
    func setCurrentTestToken(testToken: String) // TODO: refactor
}
