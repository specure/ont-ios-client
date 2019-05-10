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

public let MapOptionResponseOverlayAuto = MapOptionResponse.MapOverlays(identifier: "auto", title: NSLocalizedString("map.options.overlay.auto", value: "Auto", comment: "Map overlay description"), isDefault: true)

///
public let RMBTMapOptionsOverlayAuto = RMBTMapOptionsOverlay (
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

public let RMBTMapOptionCountryAll = RMBTMapOptionCountry(code: "all", name: NSLocalizedString("map.options.filter.all_countries", comment: "All Countries"))

///
public let RMBTMapOptionsToastInfoTitle = "title"

///
public let RMBTMapOptionsToastInfoKeys = "keys"

///
public let RMBTMapOptionsToastInfoValues = "values"

///
open class RMBTMapOptions {
    open var mapViewType: RMBTMapOptionsMapViewType = .standard

    open var overlays: [MapOptionResponse.MapOverlays] = []
    open var periodFilters: [MapOptionResponse.MapPeriodFilters] = []
    open var mapCellularTypes: [MapOptionResponse.MapCellularTypes] = []
    
    open var types: [MapOptionResponse.MapType] = []
    open var subTypes: [MapOptionResponse.MapSubType] = []

    private var _countries: [RMBTMapOptionCountry] = []
    open var countries: [RMBTMapOptionCountry] {
        if _countries.count == 0 {
            let locale = Locale.current
            let countryArray = Locale.isoRegionCodes
            var unsortedCountryArray: [RMBTMapOptionCountry] = []
            for countryCode in countryArray {
                if let displayNameString = locale.localizedString(forRegionCode: countryCode) {
                    let country = RMBTMapOptionCountry(response: [:])
                    country.code = countryCode.lowercased()
                    country.name = displayNameString
                    unsortedCountryArray.append(country)
                    if RMBTConfig.sharedInstance.RMBT_DEFAULT_IS_CURRENT_COUNTRY {
                        country.isDefault = (locale.regionCode?.lowercased() == countryCode.lowercased())
                    } else {
                        country.isDefault = false
                    }
                }
            }
            unsortedCountryArray.sort { (country1, country2) -> Bool in
                return country1.name?.compare(country2.name ?? "") == ComparisonResult.orderedAscending
            }
            
            let allCountries = RMBTMapOptionCountryAll
            if RMBTConfig.sharedInstance.RMBT_DEFAULT_IS_CURRENT_COUNTRY {
                allCountries.isDefault = true
            }
            var sortedCountryArray = [allCountries]
            sortedCountryArray.append(contentsOf: unsortedCountryArray)
            self._countries = sortedCountryArray
        }
        
        return self._countries
    }
    open var activeCountry: RMBTMapOptionCountry?
    open var activeOverlay: MapOptionResponse.MapOverlays = MapOptionResponseOverlayAuto
    open var activePeriodFilter: MapOptionResponse.MapPeriodFilters?
    open var activeCellularTypes: [MapOptionResponse.MapCellularTypes] = []
    open var activeType: MapOptionResponse.MapType?
    open var activeSubtype: MapOptionResponse.MapSubType?
    
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
    ///
    public init(response: MapOptionResponse, isSkipOperators: Bool = false, defaultMapViewType: RMBTMapOptionsMapViewType = .standard) {
        self.mapViewType = defaultMapViewType
        
        //Set overlays
        self.activeOverlay = response.mapOverlays.first(where: { (overlay) -> Bool in
            return overlay.isDefault == true
        }) ?? MapOptionResponseOverlayAuto
//        overlays.append(MapOptionResponseOverlayAuto)
        overlays.append(contentsOf: response.mapOverlays)
        
        //Set period
        periodFilters = response.mapPeriodFilters
        
        self.activePeriodFilter = periodFilters.first(where: { (period) -> Bool in
            return period.isDefault == true
        })

        if activePeriodFilter == nil {
            activePeriodFilter = periodFilters.first
        }
        
        //Set technologies
        self.mapCellularTypes = response.mapCellularTypes
        for type in self.mapCellularTypes {
            if type.isDefault == true {
                self.activeCellularTypes.append(type)
            }
        }
        
        self.types = response.mapTypes
        self.subTypes = response.mapSubTypes
        
        self.activeType = types.first(where: { (type) -> Bool in
            return type.isDefault == true
        })
        
        if activeType == nil {
            activeType = types.first
        }
        
        self.activeSubtype = subTypes.first(where: { (type) -> Bool in
            return type.isDefault == true
        })
        
        if activeSubtype == nil {
            activeSubtype = subTypes.first
        }

        if self.countries.count > 0 {
            self.activeCountry = self.countries.first(where: { (country) -> Bool in
                return country.isDefault == true
            })
            if self.activeCountry == nil {
                self.activeCountry = self.countries.first
            }
        }
        
        if let mapViewIndex = response.mapLayouts.firstIndex(where: { (layout) -> Bool in
            return layout.isDefault == true
        }),
            let mapViewType = RMBTMapOptionsMapViewType(rawValue: mapViewIndex) {
            self.mapViewType = mapViewType
        } else {
            self.mapViewType = .standard
        }
        
        self.restoreSelection()
    }
    
    public func merge(with previousMapOptions: RMBTMapOptions) {
        self.activeCountry = previousMapOptions.activeCountry
        self.activeOverlay = previousMapOptions.activeOverlay
        self.activeSubtype = previousMapOptions.activeSubtype
        self.activeOperator = previousMapOptions.activeOperator
        self.operatorsForCountry = previousMapOptions.operatorsForCountry
        self.mapViewType = previousMapOptions.mapViewType
        
        // ..then try to actually select options from app state, if we have one
        restoreSelection()
    }

    ///
    open func saveSelection() {
        let selection = RMBTMapOptionsSelection()

        selection.subtypeIdentifier = activeSubtype?.id.rawValue ?? ""
        selection.typeIdentifier = activeType?.id.rawValue ?? ""
        selection.overlayIdentifier = activeOverlay.identifier
        selection.countryIdentifier = activeCountry?.code ?? ""
        selection.periodIdentifier = activePeriodFilter?.period ?? 180
        selection.cellularTypes = activeCellularTypes.map({ (type) -> Int in
            return type.id ?? 0
        })

        RMBTSettings.sharedSettings.mapOptionsSelection = selection
    }

    ///
    fileprivate func restoreSelection() {
        let selection: RMBTMapOptionsSelection = RMBTSettings.sharedSettings.mapOptionsSelection
        
        if let id = selection.subtypeIdentifier {
            activeSubtype = self.subTypes.first(where: { (type) -> Bool in
                return type.id.rawValue == id
            })
        }
        if let id = selection.typeIdentifier {
            activeType = self.types.first(where: { (type) -> Bool in
                return type.id.rawValue == id
            })
        }
        if let id = selection.overlayIdentifier {
            activeOverlay = self.overlays.first(where: { (overlay) -> Bool in
                return overlay.identifier == id
            }) ?? MapOptionResponseOverlayAuto
        }
        if let countryIdentifier = selection.countryIdentifier {
            activeCountry = self.countries.first(where: { (country) -> Bool in
                return country.code?.lowercased() == countryIdentifier.lowercased()
            })
        }
        if let id = selection.periodIdentifier {
            activePeriodFilter = self.periodFilters.first(where: { (period) -> Bool in
                return period.period == id
            })
        }
        if selection.cellularTypes.count > 0 {
            activeCellularTypes = mapCellularTypes.filter({ (type) -> Bool in
                return selection.cellularTypes.contains(type.id ?? 0)
            })
        }
    }
    
    open func subTypes(for type: MapOptionResponse.MapType) -> [MapOptionResponse.MapSubType] {
        var subtypes: [MapOptionResponse.MapSubType] = []
        
        for index in type.mapSubTypeOptions {
            if let subtype = self.subTypes.first(where: { (type) -> Bool in
                return type.index == index
            }) {
                subtypes.append(subtype)
            }
        }
        
        return subtypes
    }
    
    ///
    open func paramsDictionary() -> [String: Any] {
        var params: [String: Any] = [:]
        if let activeType = self.activeType,
            let activeSubType = self.activeSubtype {
            params["map_options"] = activeType.id.rawValue + "/" + activeSubType.id.rawValue
        }
        if let countryCode = self.activeCountry?.code {
            params["country"] = countryCode
        } else {
            params["country"] = "all"
        }
        if let activePeriod = self.activePeriodFilter {
            params["period"] = activePeriod.period
        } else {
            params["period"] = 180
        }
        if self.activeType?.id == .cell {
            if self.activeCellularTypes.count > 0 {
                params["technology"] = self.activeCellularTypes.map({ (type) -> String in
                    return String(type.id ?? 0)
                }).joined(separator: "")
            }
        }
        
        if let activeOperator = self.activeOperator {
            params["provider"] = activeOperator.providerForRequest
        } else {
            params["provider"] = ""
        }
        
        return params
    }
    
    ///
    open func markerParamsDictionary() -> [String: Any] {
        var params: [String: Any] = [:]
        var optionsParams: [String: Any] = [:]
        var filterParams: [String: Any] = [:]
        if let activeType = self.activeType,
            let activeSubType = self.activeSubtype {
            optionsParams["map_options"] = activeType.id.rawValue + "/" + activeSubType.id.rawValue
        }
        optionsParams["overlay_type"] = activeOverlay.identifier
        if let activePeriod = self.activePeriodFilter {
            filterParams["period"] = activePeriod.period
        } else {
            filterParams["period"] = 6
        }
        if self.activeCellularTypes.count > 0 {
            filterParams["technology"] = self.activeCellularTypes.map({ (type) -> String in
                return String(type.id ?? 0)
            }).joined(separator: "")
        }
        if let activeOperator = self.activeOperator {
            filterParams["mobile_provider_name"] = activeOperator.title
        }
        
        params["options"] = optionsParams
        params["filter"] = filterParams
        return params
    }

}

open class RMBTMapOptionCountry: Equatable {
    open var code: String?
    open var name: String?
    open var isDefault: Bool = false
    
    init(code: String, name: String) {
        self.code = code
        self.name = name
    }
    
    init(response: [String: Any]) {
        self.code = response["country_code"] as? String
        self.name = response["country_name"] as? String
    }
    
    public static func == (lhs: RMBTMapOptionCountry, rhs: RMBTMapOptionCountry) -> Bool {
        return lhs.code == rhs.code
    }
}

// Used to persist selected map options between map views
open class RMBTMapOptionsSelection: NSObject {
    open var subtypeIdentifier: String?
    open var typeIdentifier: String?
    open var overlayIdentifier: String?
    open var countryIdentifier: String?
    open var periodIdentifier: Int?
    open var cellularTypes: [Int] = []
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


