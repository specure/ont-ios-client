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
class QOSFactory {

    ///
    private init() {

    }

    ///
    class func createQOSTest(_ typeString: String, params: QOSTestParameters) -> QOSTest? {
        if let type = getTypeIfEnabled(QosMeasurementType(rawValue: typeString)) {

            switch type {
                case .TCP:
                    return QOSTCPTest(testParameters: params)

                case .NonTransparentProxy:
                    return QOSNonTransparentProxyTest(testParameters: params)

                case .HttpProxy:
                    return QOSHTTPProxyTest(testParameters: params)

                case .WEBSITE:
                    return QOSWebsiteTest(testParameters: params)

                case .DNS:
                    return QOSDNSTest(testParameters: params)

                case .UDP:
                    return QOSUDPTest(testParameters: params)

                case .VOIP:
                    return QOSVOIPTest(testParameters: params)

                case .JITTER:
                    return QOSVOIPTest(testParameters: params)
                
                case .TRACEROUTE:
                    return QOSTracerouteTest(testParameters: params)
            }
        }

        return nil
    }

    ///
    class func createTestExecutor(_ testObject: QOSTest, controlConnection: QOSControlConnection? = nil, delegateQueue: DispatchQueue, speedtestStartTime: UInt64) -> QOSTestExecutorProtocol? {
        if let type = getTypeIfEnabled(testObject.getType()) {

            switch type {
                case .TCP:
                    return TCPTestExecutor(
                        controlConnection: controlConnection,
                        delegateQueue: delegateQueue,
                        testObject: testObject as! QOSTCPTest,
                        speedtestStartTime: speedtestStartTime
                    )

                case .NonTransparentProxy:
                    return NonTransparentProxyTestExecutor(
                        controlConnection: controlConnection,
                        delegateQueue: delegateQueue,
                        testObject: testObject as! QOSNonTransparentProxyTest,
                        speedtestStartTime: speedtestStartTime
                    )

                case .HttpProxy:
                    return HTTPProxyTestExecutor(
                        controlConnection: controlConnection,
                        delegateQueue: delegateQueue,
                        testObject: testObject as! QOSHTTPProxyTest,
                        speedtestStartTime: speedtestStartTime
                    )

                case .WEBSITE:
                    return WebsiteTestExecutor(
                        controlConnection: controlConnection,
                        delegateQueue: delegateQueue,
                        testObject: testObject as! QOSWebsiteTest,
                        speedtestStartTime: speedtestStartTime
                    )

                case .DNS:
                    return DNSTestExecutor(
                        controlConnection: controlConnection,
                        delegateQueue: delegateQueue,
                        testObject: testObject as! QOSDNSTest,
                        speedtestStartTime: speedtestStartTime
                    )

                case .UDP:
                    return UDPTestExecutor(
                        controlConnection: controlConnection,
                        delegateQueue: delegateQueue,
                        testObject: testObject as! QOSUDPTest,
                        speedtestStartTime: speedtestStartTime
                    )

                case .VOIP:
                    return VOIPTestExecutor(
                        controlConnection: controlConnection,
                        delegateQueue: delegateQueue,
                        testObject: testObject as! QOSVOIPTest,
                        speedtestStartTime: speedtestStartTime
                    )
                
                case .JITTER:
                    return VOIPTestExecutor(
                        controlConnection: controlConnection,
                        delegateQueue: delegateQueue,
                        testObject: testObject as! QOSVOIPTest,
                        speedtestStartTime: speedtestStartTime
                )

                case .TRACEROUTE:
                    return TracerouteTestExecutor(
                        controlConnection: controlConnection,
                        delegateQueue: delegateQueue,
                        testObject: testObject as! QOSTracerouteTest,
                        speedtestStartTime: speedtestStartTime
                    )
            }
        }

        return nil
    }

    ///
    private class func getTypeIfEnabled(_ type: QosMeasurementType?) -> QosMeasurementType? {
        if type != nil && !isEnabled(type!) {
            return nil
        }

        return type
    }

    ///
    private class func isEnabled(_ type: QosMeasurementType) -> Bool {
        return QOS_ENABLED_TESTS.contains(type)
    }
}
