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
import CoreLocation

///
/*@available(*, deprecated=1.0) */open class RMBTHistoryResultItem {
    
    ///
    open var title: String?
    
    ///
    open var value: String?
    
    ///
    open var classification: Int?
    
    ///
    public init() {
        
    }
    
    ///
    init(withResultItem item: SpeedMeasurementResultResponse.ResultItem) {
        self.title = item.title
        self.value = item.value
    }
    
    ///
    init(withClassifiedResultItem item: SpeedMeasurementResultResponse.ClassifiedResultItem) {
        self.title = item.title
        self.value = item.value
        self.classification = item.classification
    }
    
    ///
    init(withSpeedMeasurementDetailItem item: SpeedMeasurementDetailResultResponse.SpeedMeasurementDetailItem) {
        self.title = item.title
        self.value = item.value
        //item.key
    }
}

//public typealias ResultItem = SpeedMeasurementResultResponse.ResultItem
//public typealias ClassifiedResultItem = SpeedMeasurementResultResponse.ClassifiedResultItem
//public typealias SpeedMeasurementDetailItem = SpeedMeasurementDetailResultResponse.SpeedMeasurementDetailItem

///
public enum RMBTHistoryResultDataState {
    case index
    case basic
    case full
}

///
open class RMBTHistoryResult {
    
    ///
    open var dataState: RMBTHistoryResultDataState = .index
    
    ///
    open var uuid: String!
    
    ///
    open var timestamp: Date!
    
    ///
    open var timeString: String = ""
    
    ///
    open var downloadSpeedMbpsString: String!
    
    ///
    open var uploadSpeedMbpsString: String!
    
    ///
    open var shortestPingMillisString: String!
    
    ///
    open var deviceModel: String!
    
    ///
    open var coordinate: CLLocationCoordinate2D!
    
    ///
    open var locationString: String!
    
    /// "WLAN", "2G/3G" etc.
    open let networkTypeServerDescription: String!
    
    /// Available in basic details
    open var networkType: RMBTNetworkType!
    
    ///
    open var shareText: String!
    
    ///
    open var shareURL: URL!
    
    ///
    open var netItems = [RMBTHistoryResultItem]() //[ResultItem]()
    
    ///
    open var measurementItems = [RMBTHistoryResultItem]() //[ClassifiedResultItem]()
    
    /// Full details
    open var fullDetailsItems = [RMBTHistoryResultItem]() //[SpeedMeasurementDetailItem]()
    
    //
    
    ///
    fileprivate var currentYearFormatter = DateFormatter()
    
    ///
    fileprivate var previousYearFormatter = DateFormatter()
    
    //
    
    ///
    public init(response: [String: AnyObject]) { // this methods takes only ["test_uuid": ...] after a new test...
        downloadSpeedMbpsString = response["speed_download"] as? String
        uploadSpeedMbpsString = response["speed_upload"] as? String
        shortestPingMillisString = response["ping_shortest"] as? String
        
        // Note: here network_type is a string with full description (i.e. "WLAN") and in the basic details response it's a numeric code
        networkTypeServerDescription = response["network_type"] as? String
        uuid = response["test_uuid"] as? String
        
        if let model = response["model"] as? String {
            self.deviceModel = UIDeviceHardware.getDeviceNameFromPlatform(model)
        }/* else {
         self.deviceModel = "Unknown" // TODO: translate?
         } */
        
        if let time = response["time"] as? NSNumber {
            let t: TimeInterval = time.doubleValue / 1000.0
            self.timestamp = Date(timeIntervalSince1970: t)
        }
        
        coordinate = kCLLocationCoordinate2DInvalid
        
        //
        
        currentYearFormatter.dateFormat = "MMM dd HH:mm"
        previousYearFormatter.dateFormat = "MMM dd YYYY"
    }
    
    ///
    open func formattedTimestamp() -> String {
        let historyDateComponents = (Calendar.current as NSCalendar).components([.day, .month, .year], from: timestamp)
        let currentDateComponents = (Calendar.current as NSCalendar).components([.day, .month, .year], from: Date())
        
        var result = ""
        
        if currentDateComponents.year == historyDateComponents.year {
            result = currentYearFormatter.string(from: timestamp)
        } else {
            result = previousYearFormatter.string(from: timestamp)
        }
        
        // For some reason MMM on iOS7 returns "Aug." with a trailing dot, let's strip the dot manually
        return result.replacingOccurrences(of: ".", with: "")
    }
    
    ///
    open func ensureBasicDetails(_ success: @escaping EmptyCallback) { // TODO: rewrite, always get full results...
        if dataState != .index {
            success()
        } else {
            
            if RMBTConfig.sharedInstance.RMBT_VERSION_NEW {
                
                ControlServer.sharedControlServer.getSpeedMeasurement(uuid, success: { response in
                    
                    if let nt = response.networkType {
                        self.networkType = RMBTNetworkTypeMake(nt) // RMBTNetworkType(rawValue: networkType.integerValue)!
                    }
                    
                    self.shareURL = nil
                    if let shareText = response.shareText {
                        // http://stackoverflow.com/questions/14226300/i-am-getting-an-implicit-conversion-from-enumeration-type-warning-in-xcode-for
                        // TODO: verify if fixed on iOS7
                        
                        do {
                            let linkDetector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
                            
                            let matches = linkDetector.matches(in: shareText, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: shareText.characters.count))
                            
                            if matches.count > 0 {
                                let r = matches.last!
                                
                                assert(r.resultType == NSTextCheckingResult.CheckingType.link, "Invalid match type")
                                
                                self.shareText = (shareText as NSString).replacingCharacters(in: r.range, with: "")
                                self.shareURL = r.url
                            }
                            
                        } catch {
                            // ignore
                        }
                    }
                    
                    if let networkDetailList = response.networkDetailList {
                        let resultItems = networkDetailList.map({ item -> RMBTHistoryResultItem in
                            return RMBTHistoryResultItem(withResultItem: item)
                        })
                        
                        self.netItems.append(contentsOf: resultItems)
                    }
                    
                    if let classifiedMeasurementDataList = response.classifiedMeasurementDataList {
                        let resultItems = classifiedMeasurementDataList.map({ item -> RMBTHistoryResultItem in
                            return RMBTHistoryResultItem(withClassifiedResultItem: item)
                        })
                        
                        self.measurementItems.append(contentsOf: resultItems)
                    }
                    
                    if let geoLat = response.latitude, let geoLon = response.longitude {
                        self.coordinate = CLLocationCoordinate2DMake(geoLat, geoLon)
                    }
                    
                    self.timeString = response.timeString ?? ""
                    self.locationString = response.location
                    
                    self.dataState = .basic
                    
                    success()
                    
                }, error: { error in
                    // TODO: handle error
                })
            
            } else {
            
                MeasurementHistory.sharedMeasurementHistory.getMeasurementDetails_Old(uuid, full: false, success: { response in
                    
                    self.networkType = response.measurements![0].networkType.map { RMBTNetworkType(rawValue: $0) }!
                    //
                    self.shareText = nil
                    
                    self.shareText = response.measurements?[0].shareText
                    
                    do {
                        let linkDetector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
                        
                        let matches = linkDetector.matches(in: self.shareText, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: self.shareText.characters.count))
                        
                        if matches.count > 0 {
                            let r = matches.last!
                            
                            assert(r.resultType == NSTextCheckingResult.CheckingType.link, "Invalid match type")
                            
                            self.shareText = (self.shareText as NSString).replacingCharacters(in: r.range, with: "")
                            self.shareURL = (r.url! as NSURL) as URL!
                        }
                        
                    } catch {
                        
                    }
                    
                    for r in (response.measurements?[0].networkDetailList)! {
                        
                        let i=SpeedMeasurementResultResponse.ResultItem()
                        i.title = r.title
                        i.value = r.value
                        
                        self.netItems.append(RMBTHistoryResultItem(withResultItem:i))
                    }
                    
                    for r in (response.measurements?[0].classifiedMeasurementDataList)! {
                        
                        let i = SpeedMeasurementResultResponse.ClassifiedResultItem()
                        i.classification = r.classification
                        i.title = r.title
                        i.value = r.value
                        
                        //self.measurementItems.append(RMBTHistoryResultItem(response: r))
                        self.measurementItems.append(RMBTHistoryResultItem(withClassifiedResultItem:i))
                    }
                    
                    // TODO: rewrite with double if-let statement when using swift 1.2
                    if let geoLat = response.measurements?[0].latitude{
                        if let geoLon = response.measurements?[0].longitude {
                            self.coordinate = CLLocationCoordinate2DMake(geoLat, geoLon)
                        }
                    }
                    
                    if let timeString = response.measurements?[0].timeString {
                        self.timeString = timeString
                    }
                    
                    self.locationString = response.measurements?[0].location
                    
                    self.dataState = .basic
                    
                    success()
                    
                }, error: { error in
                    
                })
            }
            

        }
    }
    
    ///
    open func ensureFullDetails(_ success: @escaping EmptyCallback) {
        if dataState == .full {
            success()
        } else {
            
            ControlServer.sharedControlServer.getSpeedMeasurementDetails(uuid, success: { response in
                
                // TODO:
                
                if let speedMeasurementResultDetailList = response.speedMeasurementResultDetailList {
                    let resultItems = speedMeasurementResultDetailList.map({ item -> RMBTHistoryResultItem in
                        return RMBTHistoryResultItem(withSpeedMeasurementDetailItem: item)
                    })
                    
                    self.fullDetailsItems.append(contentsOf: resultItems)
                }
                
                self.dataState = .full
                
                success()
                
            }, error: { error in
                // TODO: handle error
            })
        }
    }
    
}
