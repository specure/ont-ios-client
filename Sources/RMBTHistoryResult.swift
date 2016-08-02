//
//  RMBTHistoryResult.swift
//  RMBT
//
//  Created by Benjamin Pucher on 31.03.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation
import CoreLocation

///
/*@available(*, deprecated=1.0) */public class RMBTHistoryResultItem {

    ///
    public var title: String?

    ///
    public var value: String?

    ///
    public var classification: Int?

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
    case Index
    case Basic
    case Full
}

///
public class RMBTHistoryResult {

    ///
    public var dataState: RMBTHistoryResultDataState = .Index

    ///
    public var uuid: String!

    ///
    public var timestamp: NSDate!

    ///
    public var timeString: String = ""

    ///
    public var downloadSpeedMbpsString: String!

    ///
    public var uploadSpeedMbpsString: String!

    ///
    public var shortestPingMillisString: String!

    ///
    public var deviceModel: String!

    ///
    public var coordinate: CLLocationCoordinate2D!

    ///
    public var locationString: String!

    /// "WLAN", "2G/3G" etc.
    public let networkTypeServerDescription: String!

    /// Available in basic details
    public var networkType: RMBTNetworkType!

    ///
    public var shareText: String!

    ///
    public var shareURL: NSURL!

    ///
    public var netItems = [RMBTHistoryResultItem]() //[ResultItem]()

    ///
    public var measurementItems = [RMBTHistoryResultItem]() //[ClassifiedResultItem]()

    /// Full details
    public var fullDetailsItems = [RMBTHistoryResultItem]() //[SpeedMeasurementDetailItem]()

    //

    ///
    private var currentYearFormatter = NSDateFormatter()

    ///
    private var previousYearFormatter = NSDateFormatter()

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
            let t: NSTimeInterval = time.doubleValue / 1000.0
            self.timestamp = NSDate(timeIntervalSince1970: t)
        }

        coordinate = kCLLocationCoordinate2DInvalid

        //

        currentYearFormatter.dateFormat = "MMM dd HH:mm"
        previousYearFormatter.dateFormat = "MMM dd YYYY"
    }

    ///
    public func formattedTimestamp() -> String {
        let historyDateComponents = NSCalendar.currentCalendar().components([.Day, .Month, .Year], fromDate: timestamp)
        let currentDateComponents = NSCalendar.currentCalendar().components([.Day, .Month, .Year], fromDate: NSDate())

        var result = ""

        if currentDateComponents.year == historyDateComponents.year {
            result = currentYearFormatter.stringFromDate(timestamp)
        } else {
            result = previousYearFormatter.stringFromDate(timestamp)
        }

        // For some reason MMM on iOS7 returns "Aug." with a trailing dot, let's strip the dot manually
        return result.stringByReplacingOccurrencesOfString(".", withString: "")
    }

    ///
    public func ensureBasicDetails(success: EmptyCallback) { // TODO: rewrite, always get full results...
        if dataState != .Index {
            success()
        } else {

            ControlServerNew.sharedControlServer.getSpeedMeasurement(uuid, success: { response in

                if let nt = response.networkType {
                    self.networkType = RMBTNetworkTypeMake(nt) // RMBTNetworkType(rawValue: networkType.integerValue)!
                }

                self.shareURL = nil
                if let shareText = response.shareText {
                    // http://stackoverflow.com/questions/14226300/i-am-getting-an-implicit-conversion-from-enumeration-type-warning-in-xcode-for
                    // TODO: verify if fixed on iOS7

                    do {
                        let linkDetector = try NSDataDetector(types: NSTextCheckingType.Link.rawValue)

                        let matches = linkDetector.matchesInString(shareText, options: NSMatchingOptions(rawValue: 0), range: NSRange(location: 0, length: shareText.characters.count))

                        if matches.count > 0 {
                            let r = matches.last!

                            assert(r.resultType == NSTextCheckingType.Link, "Invalid match type")

                            self.shareText = (shareText as NSString).stringByReplacingCharactersInRange(r.range, withString: "")
                            self.shareURL = r.URL
                        }

                    } catch {
                        // ignore
                    }
                }

                if let networkDetailList = response.networkDetailList {
                    let resultItems = networkDetailList.map({ item -> RMBTHistoryResultItem in
                        return RMBTHistoryResultItem(withResultItem: item)
                    })

                    self.netItems.appendContentsOf(resultItems)
                }

                if let classifiedMeasurementDataList = response.classifiedMeasurementDataList {
                    let resultItems = classifiedMeasurementDataList.map({ item -> RMBTHistoryResultItem in
                        return RMBTHistoryResultItem(withClassifiedResultItem: item)
                    })

                    self.measurementItems.appendContentsOf(resultItems)
                }

                if let geoLat = response.latitude, geoLon = response.longitude {
                    self.coordinate = CLLocationCoordinate2DMake(geoLat, geoLon)
                }

                self.timeString = response.timeString ?? ""
                self.locationString = response.location

                self.dataState = .Basic

                success()

            }, error: { error in
                // TODO: handle error
            })
        }
    }

    ///
    public func ensureFullDetails(success: EmptyCallback) {
        if dataState == .Full {
            success()
        } else {

            ControlServerNew.sharedControlServer.getSpeedMeasurementDetails(uuid, success: { response in

                // TODO:

                if let speedMeasurementResultDetailList = response.speedMeasurementResultDetailList {
                    let resultItems = speedMeasurementResultDetailList.map({ item -> RMBTHistoryResultItem in
                        return RMBTHistoryResultItem(withSpeedMeasurementDetailItem: item)
                    })

                    self.fullDetailsItems.appendContentsOf(resultItems)
                }

                self.dataState = .Full

                success()

            }, error: { error in
                // TODO: handle error
            })
        }
    }

}
