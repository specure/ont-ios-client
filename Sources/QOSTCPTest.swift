//
//  QOSTCPTest.swift
//  RMBT
//
//  Created by Benjamin Pucher on 05.12.14.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

import Foundation

///
class QOSTCPTest: QOSTest {

    private let PARAM_PORT_OUT = "out_port"
    private let PARAM_PORT_IN = "in_port"

    //

    var portOut: UInt16?
    var portIn: UInt16?

    //

    ///
    override var description: String {
        return super.description + ", [portOut: \(portOut), portIn: \(portIn)]"
    }

    //

    ///
    override init(testParameters: QOSTestParameters) {
        // portOut
        if let portOutString = testParameters[PARAM_PORT_OUT] as? String {
            if let portOut = UInt16(portOutString) {
                self.portOut = portOut
            }
        }

        // portIn
        if let portInString = testParameters[PARAM_PORT_IN] as? String {
            if let portIn = UInt16(portInString) {
                self.portIn = portIn
            }
        }

        super.init(testParameters: testParameters)
    }

    ///
    override func getType() -> QOSTestType! {
        return .TCP
    }

}
