/*****************************************************************************************************
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

///
typealias WebsiteTestExecutor = QOSWebsiteTestExecutor<QOSWebsiteTest>

///
class QOSWebsiteTestExecutor<T: QOSWebsiteTest>: QOSTestExecutorClass<T> {

    private let RESULT_WEBSITE_URL      = "website_objective_url"
    private let RESULT_WEBSITE_TIMEOUT  = "website_objective_timeout"
    private let RESULT_WEBSITE_DURATION = "website_result_duration"
    private let RESULT_WEBSITE_STATUS   = "website_result_status"
    private let RESULT_WEBSITE_INFO     = "website_result_info"
    private let RESULT_WEBSITE_RX_BYTES = "website_result_rx_bytes"
    private let RESULT_WEBSITE_TX_BYTES = "website_result_tx_bytes"

    //
    private var requestStartTimeTicks: UInt64 = 0
    

    //

    ///
    override init(controlConnection: QOSControlConnection, delegateQueue: DispatchQueue, testObject: T, speedtestStartTime: UInt64) {
        super.init(controlConnection: controlConnection, delegateQueue: delegateQueue, testObject: testObject, speedtestStartTime: speedtestStartTime)
    }

    ///
    override func startTest() {
        super.startTest()

        testResult.set(RESULT_WEBSITE_URL, value: testObject.url as AnyObject?)
        testResult.set(RESULT_WEBSITE_TIMEOUT, number: testObject.timeout)
    }

    ///
    override func executeTest() {
        
        if let url = testObject.url {
        
            qosLog.debug("EXECUTING WEBSITE TEST")
            
            if let testURL = URL(string: url) {
                do {
                    requestStartTimeTicks = getCurrentTimeTicks()
                    guard let theUrlData = try? Data(contentsOf: testURL) else { return }
                    
                    let durationInNanoseconds = getTimeDifferenceInNanoSeconds(self.requestStartTimeTicks)
                    self.testResult.resultDictionary[self.RESULT_WEBSITE_DURATION] = NSNumber(value: durationInNanoseconds)
                    
                    self.callFinishCallback()
                    
                } catch {
                
                }
                
            }
            
        }
    }

    ///
    override func needsControlConnection() -> Bool {
        return false
    }
}
