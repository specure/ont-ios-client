//
//  RMBTHelpers.swift
//  RMBT
//
//  Created by Benjamin Pucher on 02.04.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation
import UIKit

///
func RMBTIsRunningOnWideScreen() -> Bool {
    return (UIScreen.mainScreen().bounds.size.height >= 568)
}
