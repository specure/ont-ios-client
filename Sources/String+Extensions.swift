//
//  String+Extensions.swift
//  RMBT
//
//  Created by Benjamin Pucher on 20.01.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
extension String {

    ///
    public func trim() -> String {
        return self.stringByTrimmingCharactersInSet(.whitespaceAndNewlineCharacterSet())
    }

    ///
    public func stringByRemovingAllNewlines() -> String {
        return self.stringByReplacingOccurrencesOfString("\n", withString: "", options: .LiteralSearch, range: nil)
    }

    ///
    public func stringByRemovingLastNewline() -> String { // TODO: improve...
        return self.stringByReplacingOccurrencesOfString("\n", withString: "", options: .BackwardsSearch, range: self.endIndex.advancedBy(-2)..<self.endIndex)
    }

}
