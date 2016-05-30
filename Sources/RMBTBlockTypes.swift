//
//  RMBTBlockTypes.swift
//  RMBT
//
//  Created by Benjamin Pucher on 17.09.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
public typealias EmptyCallback = () -> ()

///
public typealias SuccessCallback = (response: AnyObject) -> ()

///
public typealias ErrorCallback = (error: NSError, info: NSDictionary?) -> ()

/// old block types
public typealias RMBTBlock = EmptyCallback
public typealias RMBTSuccessBlock = SuccessCallback
public typealias RMBTErrorBlock = ErrorCallback
