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

// Would not be needed when all details remains as Strings as it is in the NKOM project
extension RMBTHistoryResultItem {
    
    ///
    open func convertValueToString() -> String {
        
        if let stringItemValue = self.value as? String {
            return stringItemValue
        } else if let numberItemValue = self.value as? NSNumber {
            return String(describing: numberItemValue)
        }
        
        return ""
    }
}

///
/*@available(*, deprecated=1.0) */open class RMBTHistoryResultItem {
    
    ///
    open var title: String?
    
    ///
    open var value: Any?
    
    ///
    open var classification: Int?
    
    ///
    public init() {
        
    }
    
    ///
    public init(withResultItem item: SpeedMeasurementResultResponse.ResultItem) {
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
    
    ////
    ///
    open var jitterMsString: String = "-"
    
    ///
    open var packetLossPercentageString: String = "-"
    
    ///
    open var jpl:VoipTest?
    
    ///
    open var shortestPingMillisString: String!
    
    ///
    open var deviceModel: String!
    
    ///
    open var coordinate: CLLocationCoordinate2D!
    
    ///
    open var locationString: String!
    
    /// "WLAN", "2G/3G" etc.
    public let networkTypeServerDescription: String!
    
    /// Available in basic details
    open var networkType: RMBTNetworkType!
    
    open var networkName: String? {
        get {
            return operatorName == nil ? _networkName : operatorName
        }
        set {
            _networkName = newValue
        }
    }
    open var operatorName: String?
    open var _networkName: String?
    
    open var qosResults: String? = "-"
    
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
    private var currentYearFormatter = DateFormatter()
    
    ///
    private var previousYearFormatter = DateFormatter()
    //
    
    ///
    public init(response: HistoryItem) { // this methods takes only ["test_uuid": ...] after a new test...
        
        operatorName = response.operatorName
        _networkName = response.networkName
        qosResults = response.qosResult
        downloadSpeedMbpsString = response.speedDownload
        uploadSpeedMbpsString = response.speedUpload
        shortestPingMillisString = response.pingShortest
        
        // Note: here network_type is a string with full description (i.e. "WLAN") and in the basic details response it's a numeric code
        networkTypeServerDescription = response.networkType
        uuid = response.testUuid
        
        if let model = response.model {
            self.deviceModel = UIDeviceHardware.getDeviceNameFromPlatform(model)
        }/* else {
         self.deviceModel = "Unknown" // TODO: translate?
         } */
        
        if let time = response.time as NSNumber? {
            let t: TimeInterval = time.doubleValue / 1000.0
            self.timestamp = Date(timeIntervalSince1970: t)
        }
        
        coordinate = kCLLocationCoordinate2DInvalid
        
        if let theJpl = response.jpl {
            
            if let resultJitter = theJpl.voip_result_jitter {
                jitterMsString = resultJitter
            }
        
            if let resultPackeLoss = theJpl.voip_result_packet_loss {
                packetLossPercentageString = resultPackeLoss
            }
            
            jpl = theJpl
        }
        
        //
        
        currentYearFormatter.dateFormat = "MMM dd HH:mm"
        previousYearFormatter.dateFormat = "MMM dd YYYY"
    }
    
    open func latitude() -> String {
        var latText = ""

        // leave this code as fallback if locationString is not available
        let latitude = self.coordinate.latitude
        latText = String(format: "%f", latitude)
        
        if let locationString = self.locationString { // TODO: use single if let statement (swift 1.2)
            let splittedLocationString = locationString.components(separatedBy: " ")
            
            if splittedLocationString.count > 1 {
                latText = String(format: "%@ %@", splittedLocationString[0], splittedLocationString[1])
            }
        }
        
        return latText
    }
    
    open func longitude() -> String {
        var longText = ""

        // leave this code as fallback if locationString is not available
        let longitute = self.coordinate.longitude
        longText = String(format: "%f", longitute)
        
        if let locationString = self.locationString {
            let splittedLocationString = locationString.components(separatedBy: " ")
            
            // this is nasty,..most probably an issue with DB
            // because this string sometimes has 2 spaces in it... (or split worked not the same as componentSeparatedByString)
            if splittedLocationString.count > 4 {
                longText = String(format: "%@ %@", splittedLocationString[3], splittedLocationString[4])
            } else if splittedLocationString.count > 1 {
                longText = splittedLocationString[1]
            }
        }
        
        return longText
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
            
            MeasurementHistory.sharedMeasurementHistory.getMeasurementDetails_Old(uuid, full: false, success: { response in
                
                if let res = response.measurements?.first {
                    self.networkType = res.networkType.map { RMBTNetworkType(rawValue: $0) }!
                    //
                    self.shareText = nil
                    
                    self.shareText = res.shareText
                    
                    do {
                        let linkDetector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
                        
                        let matches = linkDetector.matches(in: self.shareText, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange(location: 0, length: self.shareText.count))
                        
                        if matches.count > 0 {
                            let r = matches.last!
                            
                            assert(r.resultType == NSTextCheckingResult.CheckingType.link, "Invalid match type")
                            
                            self.shareText = (self.shareText as NSString).replacingCharacters(in: r.range, with: "")
                            self.shareURL = r.url
                        }
                        
                    } catch {
                        
                    }
                    
                    // Add items
                    for r in res.networkDetailList! {
                        
                        let i = SpeedMeasurementResultResponse.ResultItem()
                        i.title = r.title
                        i.value = r.value
                        
                        self.netItems.append(RMBTHistoryResultItem(withResultItem:i))
                    }
                    
                    for r in (res.classifiedMeasurementDataList)! {
                        
                        let i = SpeedMeasurementResultResponse.ClassifiedResultItem()
                        i.classification = r.classification
                        i.title = r.title
                        i.value = r.value
                
                        self.measurementItems.append(RMBTHistoryResultItem(withClassifiedResultItem:i))
                    }
                    
                    let jitter = res.classifiedMeasurementDataList?.filter({ item in
                        return  item.title == NSLocalizedString("RBMT-BASE-JITTER", comment: "JITTER")}).first
                    // TODO
                    // delete after the new server version that has jpl in the loop above comes alive
                    if let theJpl = res.jpl, jitter == nil {
                        
                        //
                        let itemJitter = SpeedMeasurementResultResponse.ClassifiedResultItem()
                        itemJitter.classification = theJpl.classification_jitter as? Int
                        itemJitter.title = NSLocalizedString("RBMT-BASE-JITTER", comment: "JITTER")
                        itemJitter.value = theJpl.voip_result_jitter?.addMsString()
                        
                        self.measurementItems.append(RMBTHistoryResultItem(withClassifiedResultItem:itemJitter))
                        
                        //
                        let itemPacketLoss = SpeedMeasurementResultResponse.ClassifiedResultItem()
                        itemPacketLoss.classification = response.measurements?[0].jpl?.classification_packet_loss as? Int
                        itemPacketLoss.title = NSLocalizedString("RBMT-BASE-PACKETLOSS", comment: "Packet loss")
                        itemPacketLoss.value = theJpl.voip_result_packet_loss?.addPercentageString()
                        
                        self.measurementItems.append(RMBTHistoryResultItem(withClassifiedResultItem:itemPacketLoss))
                    }
                    ///////////////////////////////////////////////////////////////////////////////////////////////////
                    
                    if let geoLat = res.latitude{
                        if let geoLon = response.measurements?[0].longitude {
                            self.coordinate = CLLocationCoordinate2DMake(geoLat, geoLon)
                        }
                    }
                    
                    if let timeString = res.timeString {
                        self.timeString = timeString
                    }
                    
                    self.locationString = res.location
                    
                    self.dataState = .basic
                }

                
                success()
                
            }, error: { error in
                
            })
        }
    }
    
    ///
    open func ensureFullDetails(_ success: @escaping EmptyCallback) {
        if dataState == .full {
            success()
        } else {
            
            ControlServer.sharedControlServer.getHistoryResultWithUUID_Full(uuid: uuid, success: { respose in
            
                if let speedMeasurementResultDetailList = respose.speedMeasurementResultDetailList {
                    let resultItems = speedMeasurementResultDetailList.map({ item -> RMBTHistoryResultItem in
                        return RMBTHistoryResultItem(withSpeedMeasurementDetailItem: item)
                    })
                    
                    self.fullDetailsItems.append(contentsOf: resultItems)
                }
                
                self.dataState = .full
                
                success()
            
            }, error: { _ in
            
            })
        }
    }
}
