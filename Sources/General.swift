//
//  General.swift
//  RMBT
//
//  Created by Sergey Glushchenko on 10/24/18.
//  Copyright © 2018 SPECURE GmbH. All rights reserved.
//

import Foundation

enum Environment {
    case Debug
    case Test
    case Beta
    case Release
}

#if DEBUG
let currentEnvironment = Environment.Debug
#elseif TEST
let currentEnvironment = Environment.Test
#elseif BETA
let currentEnvironment = Environment.Beta
#else
let currentEnvironment = Environment.Release
#endif
