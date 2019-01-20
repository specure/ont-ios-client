/*****************************************************************************************************
 * Copyright 2016 SPECURE GmbH
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
import ObjectMapper

///
open class MapOptionResponse: BasicResponse {
    enum MapTypesIdentifier: String {
        case mobile
        case wifi
        case browser
        case all
    }
    
    enum MapSubTypesIdentifier: String {
        case download
        case upload
        case ping
        case signal
    }
    
    var mapTypes: [MapType] = []
    var mapSubTypes: [MapSubType] = []
    var mapCellularTypes: [MapCellularTypes] = []
    var mapPeriodFilters: [MapPeriodFilters] = []
    var mapOverlays: [MapOverlays] = []
    var mapStatistics: [MapStatistics] = []
    var mapLayouts: [MapLayout] = []
    
    override open func mapping(map: Map) {
        super.mapping(map: map)

        mapCellularTypes <- map["mapCellularTypes"]
        mapSubTypes <- map["mapSubTypes"]
        mapStatistics <- map["mapStatistics"]
        mapOverlays <- map["mapOverlays"]
        mapTypes <- map["mapTypes"]
        mapLayouts <- map["mapLayouts"]
        mapPeriodFilters <- map["mapPeriodFilters"]
    }

    open class MapSubType: DefaultMappable {
        var heatmapCaptions: [String] = []
        var heatmapColors: [String] = []
        var isDefault: Bool = false
        var index: Int = 0
        var id: MapSubTypesIdentifier = .download
        var title: String?
       
        open override func mapping(map: Map) {
            heatmapCaptions       <- map["heatmap_captions"]
            heatmapColors         <- map["heatmap_colors"]
            isDefault             <- map["default"]
            index                 <- map["index"]
            id                    <- map["id"]
            title                 <- map["title"]
        }
    }

    open class MapType: DefaultMappable {
        var id: MapTypesIdentifier = .mobile
        var title: String?
        var mapListOptions: Int = 0
        var mapSubTypeOptions: [Int] = []
        var isMapCellularTypeOptions: Bool = false
        var isDefault: Bool = false

        open override func mapping(map: Map) {
            id                          <- map["id"]
            title                       <- map["title"]
            mapListOptions              <- map["mapListOptions"]
            mapSubTypeOptions           <- map["mapSubTypeOptions"]
            isMapCellularTypeOptions    <- map["mapCellularTypeOptions"]
            isDefault                   <- map["default"]
        }
    }
    
    open class MapCellularTypes: DefaultMappable, Equatable {
        open var id: String?
        open var title: String?
        open var isDefault: Bool = false
        
        required public init?(map: Map) {
            super.init()
        }
        
        open override func mapping(map: Map) {
            id          <- map["id"]
            title       <- map["title"]
            isDefault   <- map["default"]
        }
        
        public static func == (lhs: MapOptionResponse.MapCellularTypes, rhs: MapOptionResponse.MapCellularTypes) -> Bool {
            return lhs.id == rhs.id && lhs.title == rhs.title
        }
    }
    
    open class MapPeriodFilters: DefaultMappable, Equatable {
        open var period: Int = 0
        open var title: String?
        open var isDefault: Bool = false
        
        required public init?(map: Map) {
            super.init()
        }
        
        open override func mapping(map: Map) {
            period      <- map["period"]
            title       <- map["title"]
            isDefault   <- map["default"]
        }
        
        public static func == (lhs: MapOptionResponse.MapPeriodFilters, rhs: MapOptionResponse.MapPeriodFilters) -> Bool {
            return lhs.period == rhs.period && lhs.title == rhs.title
        }
    }
    
    open class MapOverlays: MapOptionResponse.DefaultMappable, Equatable {
        open var identifier: String?
        open var title: String?
        open var isDefault: Bool = false
        
        init(identifier: String, title: String, isDefault: Bool = false) {
            super.init()
            self.identifier = identifier
            self.title = title
            self.isDefault = isDefault
        }
        
        required public init?(map: Map) {
            super.init()
        }
        
        open override func mapping(map: Map) {
            identifier  <- map["id"]
            title       <- map["title"]
            isDefault   <- map["default"]
        }
        
        public static func == (lhs: MapOptionResponse.MapOverlays, rhs: MapOptionResponse.MapOverlays) -> Bool {
            return lhs.identifier == rhs.identifier && lhs.title == rhs.title
        }
    }
    
    open class MapStatistics: DefaultMappable {
        var title: String?
        var value: Float = 0.0
        
        open override func mapping(map: Map) {
            title       <- map["title"]
            value       <- map["value"]
        }
    }
    
    open class MapLayout: DefaultMappable {
        var title: String?
        var isDefault: Bool = false
        var apiLink: String?
        var accessToken: String?
        var layer: String?
        
        open override func mapping(map: Map) {
            title           <- map["title"]
            apiLink         <- map["apiLink"]
            accessToken     <- map["accessToken"]
            layer           <- map["layer"]
            isDefault       <- map["default"]
        }
    }
    
    
    open class DefaultMappable: Mappable {
        open func mapping(map: Map) {
        }
        
        init() {
            
        }
        
        required public init?(map: Map) {
            
        }
    }
    
}
