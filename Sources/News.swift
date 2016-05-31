//
//  News.swift
//  RMBTClient
//
//  Created by Benjamin Pucher on 19.09.14.
//  Copyright © 2014 SPECURE GmbH. All rights reserved.
//

import Foundation

///
public final class News {

    ///
    public let title: String

    ///
    public let text: String

    ///
    public let uid: UInt

    ///
    public init(response: [String: AnyObject]) {
        self.title = response["title"] as! String
        self.text = response["text"] as! String
        self.uid = (response["uid"] as! NSNumber).unsignedLongValue
    } // TODO: does this work? casts to NSString and CLong?
}
