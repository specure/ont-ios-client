//
//  QOSFactory.swift
//  RMBT
//
//  Created by Benjamin Pucher on 11.02.15.
//  Copyright © 2015 SPECURE GmbH. All rights reserved.
//

import Foundation

///
class QOSFactory {

    ///
    private init() {

    }

    ///
    class func createQOSTest(typeString: String, params: QOSTestParameters) -> QOSTest? {
        if let type = getTypeIfEnabled(QOSMeasurementType(rawValue: typeString)) {

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

                case .TRACEROUTE:
                    return QOSTracerouteTest(testParameters: params)
            }
        }

        return nil
    }

    ///
    class func createTestExecutor(testObject: QOSTest, controlConnection: QOSControlConnection, delegateQueue: dispatch_queue_t, speedtestStartTime: UInt64) -> QOSTestExecutorProtocol? {
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
    private class func getTypeIfEnabled(type: QOSMeasurementType?) -> QOSMeasurementType? {
        if type != nil && !isEnabled(type!) {
            return nil
        }

        return type
    }

    ///
    private class func isEnabled(type: QOSMeasurementType) -> Bool {
        return QOS_ENABLED_TESTS.contains(type)
    }
}
