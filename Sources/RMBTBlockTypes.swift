//
//  RMBTBlockTypes.swift
//  RMBT
//
//  Created by Benjamin Pucher on 17.09.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
typealias EmptyCallback = () -> ()

///
typealias SuccessCallback = (response: AnyObject) -> ()

///
typealias ErrorCallback = (error: NSError, info: NSDictionary?) -> ()

/// old block types
typealias RMBTBlock = EmptyCallback
typealias RMBTSuccessBlock = SuccessCallback
typealias RMBTErrorBlock = ErrorCallback
