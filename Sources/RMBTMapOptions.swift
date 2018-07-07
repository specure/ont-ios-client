/*****************************************************************************************************
 * Copyright 2013 appscape gmbh
 * Copyright 2014-2016 SPECURE GmbH
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *****************************************************************************************************/

import Foundation

// TODO: rewrite to seperate files

///
public enum RMBTMapOptionsMapViewType: Int {
    case standard = 0
    case satellite = 1
    case hybrid = 2
}

///
public let RMBTMapOptionsOverlayAuto = RMBTMapOptionsOverlay(
    identifier: "auto",
    localizedDescription: NSLocalizedString("map.options.overlay.auto", value: "Auto", comment: "Map overlay description")
)

///
public let RMBTMapOptionsOverlayHeatmap = RMBTMapOptionsOverlay(
    identifier: "heatmap",
    localizedDescription: NSLocalizedString("map.options.overlay.heatmap", value: "Heatmap", comment: "Map overlay description")
)

///
public let RMBTMapOptionsOverlayPoints = RMBTMapOptionsOverlay(
    identifier: "points",
    localizedDescription: NSLocalizedString("map.options.overlay.points", value: "Points", comment: "Map overlay description")
)
public let RMBTMapOptionsOverlayShapes = RMBTMapOptionsOverlay(
    identifier: "shapes",
    localizedDescription: NSLocalizedString("map.options.overlay.shapes", value: "Shapes", comment: "Map overlay description")
)
 //
public let RMBTMapOptionsOverlayRegions = RMBTMapOptionsOverlay(
    identifier: "regions",
    localizedDescription: NSLocalizedString("map.options.overlay.regions", value: "Regions", comment: "Map overlay description")
)
public let RMBTMapOptionsOverlayMunicipality = RMBTMapOptionsOverlay(
    identifier: "municipality",
    localizedDescription: NSLocalizedString("map.options.overlay.municipality", value: "Municipality", comment: "Map overlay description")
)
public let RMBTMapOptionsOverlaySettlements = RMBTMapOptionsOverlay(
    identifier: "settlements",
    localizedDescription: NSLocalizedString("map.options.overlay.settlements", value: "Settlements", comment: "Map overlay description")
)
public let RMBTMapOptionsOverlayWhitespots = RMBTMapOptionsOverlay(
    identifier: "whitespots",
    localizedDescription: NSLocalizedString("map.options.overlay.whitespots", value: "White spots", comment: "Map overlay description")
)

///
public let RMBTMapOptionsToastInfoTitle = "title"

///
public let RMBTMapOptionsToastInfoKeys = "keys"

///
public let RMBTMapOptionsToastInfoValues = "values"

///
open class RMBTMapOptions {

    ///
    open var mapViewType: RMBTMapOptionsMapViewType = .standard

    ///
    open var types = [RMBTMapOptionsType]()

    ///
    open var overlays: [RMBTMapOptionsOverlay]

    ///
    open var activeSubtype: RMBTMapOptionsSubtype

    ///
    open var activeOverlay: RMBTMapOptionsOverlay = RMBTMapOptionsOverlayAuto
    
    open var activeCountry: RMBTMapOptionCountry?
    
    open var counties: [RMBTMapOptionCountry] = []
    
    open var operatorsForCountry: [OperatorsResponse.Operator] = []
    open var activeOperator: OperatorsResponse.Operator?
    open var defaultOperator: OperatorsResponse.Operator? {
        get {
            for op in operatorsForCountry {
                if op.isDefault {
                    return op
                }
            }
            
            return nil
        }
    }
    //
    
    var isOld = true

    ///
    public init(response: NSDictionary, isOld: Bool = true) {
        self.isOld = isOld
        overlays = [
            RMBTMapOptionsOverlayAuto, RMBTMapOptionsOverlayHeatmap, RMBTMapOptionsOverlayPoints, /*RMBTMapOptionsOverlayShapes,*/
            //RMBTMapOptionsOverlayRegions, RMBTMapOptionsOverlayMunicipality, RMBTMapOptionsOverlaySettlements, RMBTMapOptionsOverlayWhitespots
        ]
        
        if isOld == true {
            overlays.append(contentsOf: [
                RMBTMapOptionsOverlayRegions, RMBTMapOptionsOverlayMunicipality, RMBTMapOptionsOverlaySettlements, RMBTMapOptionsOverlayWhitespots
                ])
        }

        if let responseCountries = (response["mapCountries"] as? [[String: Any]]) {
            self.counties = responseCountries.map({ (response) -> RMBTMapOptionCountry in
                return RMBTMapOptionCountry(response: response)
            })
        }

        // Root element, always the same
        let responseRoot = response["mapfilter"] as! NSDictionary

        let filters = responseRoot["mapFilters"] as! NSDictionary

        for typeResponse in (responseRoot["mapTypes"] as! [[String:AnyObject]]) {
            let type = RMBTMapOptionsType(response: typeResponse)
            types.append(type)

            // Process filters for this type
            for filterResponse in (filters[type.identifier] as! [[String:AnyObject]]) {
                if isOld == false {
                if let f = filterResponse["options"] as? [[String: Any]],
                    let _ = f.last?["operator"] {
                    continue
                }
                }
                let filter = RMBTMapOptionsFilter(response: filterResponse)
                type.addFilter(filter)
            }
        }

        // Select first subtype of first type as active per default
        activeSubtype = types[0].subtypes[0]
        
        if counties.count > 0 {
            self.activeCountry = counties.first
        }

        // ..then try to actually select options from app state, if we have one
        restoreSelection()
    }
    
    public func merge(with previousMapOptions: RMBTMapOptions) {
        self.activeCountry = previousMapOptions.activeCountry
        self.activeOverlay = previousMapOptions.activeOverlay
        self.activeSubtype = previousMapOptions.activeSubtype
        self.activeOperator = previousMapOptions.activeOperator
        self.operatorsForCountry = previousMapOptions.operatorsForCountry
        
        // ..then try to actually select options from app state, if we have one
        restoreSelection()
    }

    /// Returns dictionary with following keys set, representing information to be shown in the toast
    open func toastInfo() -> [String: [String]] {
        var info = [String: [String]]()
        var keys = [String]()
        var values = [String]()

        info[RMBTMapOptionsToastInfoTitle] = [String(format: "%@ %@", activeSubtype.type.title, activeSubtype.title)]

        keys.append(NSLocalizedString("map.options.filter.overlay", comment: "overlay"))
        values.append(activeOverlay.localizedDescription)

        for f in activeSubtype.type.filters {
            keys.append(f.title.capitalized)
            values.append(f.activeValue.title)
        }

        info[RMBTMapOptionsToastInfoKeys] = keys
        info[RMBTMapOptionsToastInfoValues] = values

        return info
    }

    ///
    open func saveSelection() {
        let selection = RMBTMapOptionsSelection()

        selection.subtypeIdentifier = activeSubtype.identifier
        selection.overlayIdentifier = activeOverlay.identifier

        var activeFilters = [String: String]()
        for f in activeSubtype.type.filters {
            activeFilters[f.title] = f.activeValue.title
        }

        selection.activeFilters = activeFilters

        RMBTSettings.sharedSettings.mapOptionsSelection = selection
    }

    ///
    fileprivate func restoreSelection() {
        let selection: RMBTMapOptionsSelection = RMBTSettings.sharedSettings.mapOptionsSelection

        if let subtypeIdentifier = selection.subtypeIdentifier {
            for t in types {

                let st = t.subtypes.filter({ a in
                    return a.identifier == subtypeIdentifier
                }).first

                /*let st: RMBTMapOptionsSubtype? = (t.subtypes as NSArray)._b_k_match({ (a: AnyObject!) -> Bool in
                    return (a as! RMBTMapOptionsSubtype).identifier == subtypeIdentifier
                }) as? RMBTMapOptionsSubtype*/

                if let _st = st {
                    activeSubtype = _st
                    break
                } else if t.identifier == subtypeIdentifier {
                    activeSubtype = t.subtypes[0]
                }
            }
        }

        if let overlayIdentifier = selection.overlayIdentifier {
            for o in overlays {
                if o.identifier == overlayIdentifier {
                    activeOverlay = o
                    break
                }
            }
        }

        if let activeFilters = selection.activeFilters {
            for f in activeSubtype.type.filters {
                if let activeFilterValueTitle = activeFilters[f.title] {

                    if let v = f.possibleValues.filter({ a in
                        return a.title == activeFilterValueTitle
                    }).first {
                        f.activeValue = v
                    }

                    /*if let v: RMBTMapOptionsFilterValue = (f.possibleValues as NSArray)._b_k_match({ (a: AnyObject!) -> Bool in
                        return (a as! RMBTMapOptionsFilterValue).title == activeFilterValueTitle
                    }) as? RMBTMapOptionsFilterValue {
                        f.activeValue = v
                    }*/
                }
            }
        }
    }

}

open class RMBTMapOptionCountry: NSObject {
    open var code: String?
    open var name: String?
    
    init(response: [String: Any]) {
        self.code = response["country_code"] as? String
        self.name = response["country_name"] as? String
    }
}

// Used to persist selected map options between map views
open class RMBTMapOptionsSelection: NSObject {

    ///
    open var subtypeIdentifier: String!

    ///
    open var overlayIdentifier: String!

    ///
    open var activeFilters: [String: String]!
}

///
open class RMBTMapOptionsOverlay: NSObject {

    ///
    open var identifier: String

    ///
    open var localizedDescription: String

    ///
    public init(identifier: String, localizedDescription: String) {
        self.identifier = identifier
        self.localizedDescription = localizedDescription
    }
}

///
open class RMBTMapOptionsFilterValue: NSObject {

    ///
    open var title: String

    ///
    open var summary: String

    ///
    open var isDefault: Bool = false

    ///
    open var info: NSDictionary

    //

    ///
    public init(response: [String:AnyObject]) {
        self.title = response["title"] as! String
        self.summary = response["summary"] as! String

        if let _default = response["default"] as? NSNumber {
            self.isDefault = _default.boolValue
        }

        var d = response
        d.removeValue(forKey: "title")
        d.removeValue(forKey: "summary")
        d.removeValue(forKey: "default")

        // Remove empty keys // TODO: check performance!
        for key in d.keys {
            if let val = (d[key] as? String) {
                if val == "" {
                    Log.logger.debug("removing obj for key: \(key), val: \(val)")
                    d.removeValue(forKey: key)
                }
            }
        }
        info = d as NSDictionary
    }
}

///
open class RMBTMapOptionsFilter: NSObject {

    ///
    open var title: String

    ///
    open var possibleValues = [RMBTMapOptionsFilterValue]()

    ///
    open var activeValue: RMBTMapOptionsFilterValue!

    //

    ///
    public init(response: [String: AnyObject]) {
        title = response["title"] as! String

        for subresponse in (response["options"] as! [[String: AnyObject]]) {
            let filterValue = RMBTMapOptionsFilterValue(response: subresponse)

            if filterValue.isDefault {
                activeValue = filterValue
            }

            possibleValues.append(filterValue)
        }
    }
}


/// Type = mobile|cell|browser
open class RMBTMapOptionsType: NSObject {

    /// localized
    open var title: String

    /// mobile|cell|browser
    open var identifier: String!

    ///
    open var filters = [RMBTMapOptionsFilter]()

    ///
    open var subtypes = [RMBTMapOptionsSubtype]()

    ///
    fileprivate var _paramsDictionary = [String:Any]() // NSMutableDictionary!

    //

    ///
    public init(response: [String: AnyObject]) {
        title = response["title"] as! String

        super.init()

        for subresponse in (response["options"] as! [[String:AnyObject]]) {
            let subtype = RMBTMapOptionsSubtype(response: subresponse)
            subtype.type = self

            subtypes.append(subtype)

            var pathComponents = subtype.mapOptions.components(separatedBy: "/")

            // browser/signal -> browser
            if identifier == nil {
                identifier = pathComponents[0]
            } else {
                assert(identifier == pathComponents[0], "Subtype identifier invalid")
            }
        }
    }

    ///
    open func addFilter(_ filter: RMBTMapOptionsFilter) {
        filters.append(filter)
    }

    ///
    open func paramsDictionary() -> [AnyHashable: Any] {
        // if _paramsDictionary == nil {
        //    _paramsDictionary = NSMutableDictionary()

            for f in filters {
                let index = filters.index(of: f)
                // _paramsDictionary.addEntries(from: f.activeValue.info as! [AnyHashable: Any])
                _paramsDictionary.updateValue(f.activeValue.info.allValues[index!],
                                              forKey: f.activeValue.info.allKeys[index!] as! String)
            }
        // }

        return _paramsDictionary as [AnyHashable: Any]
    }

    open func toProviderType() -> OperatorsRequest.ProviderType {
            /// mobile|cell|browser
        if identifier == "mobile" {
            return .mobile
        }
        else if identifier == "wifi" {
            return .WLAN
        }
        else if identifier == "cell" {
            return .mobile
        }
        else if identifier == "browser" {
            return .browser
        }
        else {
            return .all
        }
    }
}

/// Subtype = type + up|down|signal etc. (depending on type)
open class RMBTMapOptionsSubtype: NSObject {

    ///
    open var type: RMBTMapOptionsType!

    ///
    open var identifier: String

    ///
    open var title: String

    ///
    open var summary: String

    ///
    open var mapOptions: String

    ///
    open var overlayType: String

    //

    ///
    public init(response: [String: AnyObject]) {
        self.title = response["title"] as! String
        self.summary = response["summary"] as! String
        self.mapOptions = response["map_options"] as! String
        self.overlayType = response["overlay_type"] as! String

        self.identifier = mapOptions
    }

    ///
    open func paramsDictionary() -> NSDictionary {
        let result = NSMutableDictionary(dictionary: [
            "map_options": mapOptions
        ])

        for f in type.filters {
            result.addEntries(from: f.activeValue.info as! [AnyHashable: Any])
        }

        return result
    }

    ///
    open func markerParamsDictionary() -> NSDictionary {
        let result = NSMutableDictionary(dictionary: [
            "options": [
                "map_options": mapOptions,
                "overlay_type": overlayType
            ]
        ])

        let filterResult = NSMutableDictionary()

        for f in type.filters {
            filterResult.addEntries(from: f.activeValue.info as! [AnyHashable: Any])
        }

        result.setObject(filterResult, forKey: "filter" as NSCopying)

        return result
    }
}
