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

protocol RMBTFormat {
    // - (NSString*)rmbtFormattedString;
}

/*
static NSDateFormatter *timestampFormatter = nil;
static dispatch_once_t onceToken;
dispatch_once(&onceToken, ^{
    timestampFormatter = [[NSDateFormatter alloc] init];
    [timestampFormatter setDateFormat:@"HH:mm:ss"];
});
*/
// let _cllocation_timestampFormatter: NSDateFormatter = NSDateFormatter()
// _cllocation_timestampFormatter.dateFormat = "HH:mm:ss"

///
extension CLLocation: RMBTFormat {

    ///
    func rmbtFormattedString() -> String {
        let _cllocation_timestampFormatter = DateFormatter()
        _cllocation_timestampFormatter.dateFormat = "HH:mm:ss"

        var latSeconds: Int = Int(round(abs(self.coordinate.latitude * 3600)))
        let latDegrees = latSeconds / 3600
        latSeconds = latSeconds % 3600
        let latMinutes: CLLocationDegrees = Double(latSeconds) / 60.0

        var longSeconds: Int = Int(round(abs(self.coordinate.longitude * 3600)))
        let longDegrees: Int = longSeconds / 3600
        longSeconds = longSeconds % 3600
        let longMinutes: CLLocationDegrees = Double(longSeconds) / 60.0

        let latDirection: String = (self.coordinate.latitude  >= 0) ? "N" : "S"
        let longDirection: String = (self.coordinate.longitude >= 0) ? "E" : "W"

        return String(
            format: "%@ %ld° %.3f' %@ %ld° %.3f' (+/- %.0fm)\n@%@",
            latDirection, latDegrees as CLong, latMinutes, longDirection, longDegrees as CLong, longMinutes,
            self.horizontalAccuracy, _cllocation_timestampFormatter.string(from: self.timestamp))
    }

    ///
    func rmbtFormattedArray() -> [String] {
        let cllocationTimestampFormatter = DateFormatter()
        cllocationTimestampFormatter.dateFormat = "HH:mm:ss"

        var latSeconds: Int = Int(round(abs(self.coordinate.latitude * 3600)))
        let latDegrees = latSeconds / 3600
        latSeconds = latSeconds % 3600
        let latMinutes: CLLocationDegrees = Double(latSeconds) / 60.0

        var longSeconds: Int = Int(round(abs(self.coordinate.longitude * 3600)))
        let longDegrees: Int = longSeconds / 3600
        longSeconds = longSeconds % 3600
        let longMinutes: CLLocationDegrees = Double(longSeconds) / 60.0

        let latDirection: String = (self.coordinate.latitude  >= 0) ? "N" : "S"
        let longDirection: String = (self.coordinate.longitude >= 0) ? "E" : "W"

        let position = String(format: "%@ %ld° %.3f' %@ %ld° %.3f'", latDirection, latDegrees as CLong, latMinutes, longDirection, longDegrees as CLong, longMinutes)
        let longMin = String(format: "(+/- %.0fm)", self.horizontalAccuracy)
        let locAltitude = String(format: "%.0f m", self.altitude)  // ("\(self.altitude) m")

        let locationItems: [String] = [position, longMin, cllocationTimestampFormatter.string(from: self.timestamp), locAltitude]

        return locationItems
    }
}
