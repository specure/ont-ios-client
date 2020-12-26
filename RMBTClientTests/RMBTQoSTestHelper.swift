//
//  RMBTQoSTestHelper.swift
//  RMBTClientTests
//
//  Created by Sergey Glushchenko on 4/4/18.
//

import ObjectMapper
@testable import RMBTClient

open class RMBTQoSTestHelper: NSObject {

    let mutualExclusionQueue = DispatchQueue(label: "com.specure.rmbt.qos.mutualExclusionQueue")
    
    let executorQueue = DispatchQueue(label: "com.specure.rmbt.executorQueue", attributes: DispatchQueue.Attributes.concurrent)
    
    let speedtestStartTime = UInt64.currentTimeMillis()
    
    var concurencyGroups: [RMBTConcurencyGroup] = []
    
    var concurrencyGroupArray: [QOSTest] = []
    var testCount = 0
    
    var qosTestExecutors: [String: QOSTestExecutorProtocol] = [:]
    open var completionHandler: ((_ results: Any?) -> Void) = { _ in }
    let testedType: QosMeasurementType

    var results: [QOSTestResult] = []
    
    deinit {
        print("Deinit")
    }
    
    public init(type: QosMeasurementType, testToken: String) {
        testedType = type
        self.testToken = testToken
    }
    
    public init(type: QosMeasurementType) {
        testedType = type
    }
    
    open func parseParameters() {
        let qosSettings = Mapper<QosMeasurmentResponse>().map(JSONObject: self.qosSettings)
        self.parseParameters(parameters: qosSettings!)
    }
    
    func parseParameters(parameters: QosMeasurmentResponse) {
        guard let objectives = parameters.objectives else { return }
        
        for (objectiveType, objectiveValues) in objectives {
            for (objectiveParams) in objectiveValues {
                if let type = QosMeasurementType(rawValue: objectiveType) {
//                    if type == testedType {
                        if let qosTest = QOSFactory.createQOSTest(objectiveType, params: objectiveParams),
                            let testExecutor = QOSFactory.createTestExecutor(qosTest, delegateQueue: executorQueue, speedtestStartTime: speedtestStartTime) {
                            let group = self.findConcurencyGroup(with: qosTest.concurrencyGroup)
                            group.addTestExecutor(testExecutor: testExecutor)
                            testCount += 1
                            
                            testExecutor.setCurrentTestToken(self.testToken)
//                        }
                    }
                }
            }
        }
    }
    
    func findNextConcurencyGroup() -> RMBTConcurencyGroup? {
        for group in concurencyGroups {
            if group.passedExecutors != group.testExecutors.count {
                return group
            }
        }
        
        return nil
    }
    
    func findConcurencyGroup(with id: UInt) -> RMBTConcurencyGroup {
        for group in concurencyGroups {
            if group.identifier == id {
                return group
            }
        }
        
        let group = RMBTConcurencyGroup()
        group.identifier = id
        concurencyGroups.append(group)
        return group
    }
    
    public func startNextConcurencyGroup() {
        if let concurencyGroup = self.findNextConcurencyGroup() {
            for testExecutor in concurencyGroup.testExecutors {
                if testExecutor.needsControlConnection() {
                    let qosTest = testExecutor.getTestObject()
                    let controlConnection = getControlConnection(qosTest)
                    if !controlConnection.connected {
                        // don't do this test
                        Log.logger.info("skipping test because it needs control connection but we don't have this connection. \(qosTest)")
                        concurencyGroup.removeTestExecutor(testExecutor: testExecutor)
                        testCount -= 1
                        continue
                    }
                    
                    controlConnection.setTimeout(qosTest.timeout)
                    testExecutor.setControlConnection(controlConnection)
                }
            }
            
            for testExecutor in concurencyGroup.testExecutors {
                // execute test
                executorQueue.async {
                    testExecutor.execute { [weak self, weak concurencyGroup] (testResult: QOSTestResult) in
                        self?.mutualExclusionQueue.sync { [weak self] in
                            self?.results.append(testResult)
                            concurencyGroup?.passedExecutors += 1
                            if concurencyGroup?.passedExecutors == concurencyGroup?.testExecutors.count {
                                self?.closeAllControlConnections()
                                self?.controlConnectionMap = [:]
                                self?.startNextConcurencyGroup()
                            }
                        }
                    }
                }
            }
        }
        else {
            let qosMeasurementResult = QosMeasurementResultRequest()
            qosMeasurementResult.measurementUuid = "1"
            qosMeasurementResult.testToken = testToken
            qosMeasurementResult.time = NSNumber(value: UInt64.currentTimeMillis()).intValue // currently unused on server!
            
            var testResultArray: [QOSTestResults] = []
            for testResult in results {
                testResultArray.append(testResult.resultDictionary)
            }
            qosMeasurementResult.qosResultList = testResultArray
            self.completionHandler(qosMeasurementResult)
        }
        return
        for qosTest in concurrencyGroupArray {
            let controlConnection = getControlConnection(qosTest)
            if let testExecutor = QOSFactory.createTestExecutor(qosTest, delegateQueue: executorQueue, speedtestStartTime: speedtestStartTime) {
                let key = UUID().uuidString
                qosTestExecutors[key] = testExecutor
                
                testExecutor.setCurrentTestToken(self.testToken)
                
                if testExecutor.needsControlConnection() {
                    // set control connection timeout (TODO: compute better! (not all tests may use same control connection))
                    Log.logger.debug("setting control connection timeout to \(nsToMs(qosTest.timeout)) ms")
                    controlConnection.setTimeout(qosTest.timeout)
                    
                    // TODO: DETERMINE IF TEST NEEDS CONTROL CONNECTION
                    // IF IT NEEDS IT, AND CONTROL CONNECTION CONNECT FAILED THEN SKIP THIS TEST AND DON'T SEND RESULT TO SERVER
                    if !controlConnection.connected {
                        // don't do this test
                        Log.logger.info("skipping test because it needs control connection but we don't have this connection. \(qosTest)")
                        
                        testCount -= 1
                        if testCount == 0 {
                            DispatchQueue.main.async {
                                self.completionHandler(nil)
                            }
                        }
                        //                        DispatchQueue.main.async {
                        //                            self.qosTestFinishedWithResult(qosTest.getType(), withTestResult: nil) // no result because test didn't run
                        //                        }
                        
                        
                        
                        continue
                    }
                }
                
                Log.logger.debug("starting execution of test: \(qosTest)")
                
                // execute test
                executorQueue.async {
                    testExecutor.execute { [weak self] (testResult: QOSTestResult) in
                        self?.mutualExclusionQueue.sync { [weak self] in
                            self?.qosTestExecutors[key] = nil
                            self?.testCount -= 1
                            if self?.testCount == 0 {
                                self?.completionHandler(nil)
                            }
                            //                            qosTestFinishedWithResult(testResult.testType, withTestResult: testResult)
                        }
                    }
                }
            }
        }
    }
    
    ///
    private func getControlConnection(_ qosTest: QOSTest) -> QOSControlConnection {
        // determine control connection
        let controlConnectionKey: String = "\(qosTest.serverAddress)_\(qosTest.serverPort)_\(qosTest.getType().rawValue)"
        
        // TODO: make instantiation of control connection synchronous with locks!
        var conn: QOSControlConnection! = self.controlConnectionMap[controlConnectionKey]
        if conn == nil {
            Log.logger.debug("\(controlConnectionKey): trying to open new control connection")
            // logger.debug("NO CONTROL CONNECTION PRESENT FOR \(controlConnectionKey), creating a new one")
            Log.logger.debug("\(controlConnectionKey): BEFORE LOCK")
            
            // TODO: fail after timeout if qos server not available
            
            conn = QOSControlConnection(testToken: testToken)
            // conn.delegate = self
            
            // connect
            /* let isConnected = */_ = conn.connect(qosTest.serverAddress, onPort: qosTest.serverPort) // blocking
            
            // logger.debug("AFTER LOCK: have control connection?: \(isConnected)")
            // TODO: return nil? if not connected
            
            Log.logger.debug("\(controlConnectionKey): AFTER LOCK -> CONTROL CONNECTION READY TO USE")
            
            controlConnectionMap[controlConnectionKey] = conn
        } else {
            Log.logger.debug("\(controlConnectionKey): control connection already opened")
        }
        
        if !conn.connected {
            // reconnect
            _ = conn.connect(qosTest.serverAddress, onPort: qosTest.serverPort)
        }
        
        return conn
    }
    
    private func closeAllControlConnections() {
        Log.logger.info("closing all control connections")
        
        // TODO: if everything is done: close all control connections
        for (_, controlConnection) in self.controlConnectionMap {
            Log.logger.debug("closing control connection \(controlConnection)")
            controlConnection.disconnect()
        }
        
    }
    
    private var controlConnectionMap: [String: QOSControlConnection] = [:]
    
    
    var uuid: String = "2b0b8c7f-0147-4f1d-8893-6e6f00084e6e"
    var testToken: String = "2b0b8c7f-0147-4f1d-8893-6e6f00084e6e_1522809456_k/vLHTg8ztQ+c1xPMzv58rH6tkU="
    var qosSettings: [String: Any] {
        get {
            return [
                "objectives": [
                    "udp": [
                        [
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "qos_test_uid" : "101",
                            "timeout" : "5000000000",
                            "out_port" : "5004",
                            "out_num_packets" : "1"
                        ],
                        [
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "qos_test_uid" : "102",
                            "timeout" : "5000000000",
                            "out_port" : "123",
                            "out_num_packets" : "1"
                        ],
                        [
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "qos_test_uid" : "103",
                            "timeout" : "5000000000",
                            "out_port" : "27015",
                            "out_num_packets" : "1"
                        ],
                        [
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "qos_test_uid" : "104",
                            "timeout" : "5000000000",
                            "out_port" : "53",
                            "out_num_packets" : "1"
                        ],
                        [
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "qos_test_uid" : "119",
                            "timeout" : "5000000000",
                            "out_port" : "500",
                            "out_num_packets" : "1"
                        ],
                        [
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "qos_test_uid" : "120",
                            "timeout" : "5000000000",
                            "out_port" : "5060",
                            "out_num_packets" : "1"
                        ],
                        [
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "qos_test_uid" : "121",
                            "timeout" : "5000000000",
                            "out_port" : "27005",
                            "out_num_packets" : "1"
                        ],
                        [
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "qos_test_uid" : "122",
                            "timeout" : "5000000000",
                            "out_port" : "554",
                            "out_num_packets" : "1"
                        ],
                        [
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "qos_test_uid" : "123",
                            "timeout" : "5000000000",
                            "out_port" : "5005",
                            "out_num_packets" : "1"
                        ],
                        [
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "qos_test_uid" : "124",
                            "timeout" : "5000000000",
                            "out_port" : "7078",
                            "out_num_packets" : "1"
                        ],
                        [
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "qos_test_uid" : "157",
                            "timeout" : "5000000000",
                            "out_port" : "7082",
                            "out_num_packets" : "1"
                        ]
                    ],
                    "dns" : [
                        [
                            "concurrency_group" : "600",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "87",
                            "timeout" : "5000000000",
                            "host" : "www.google.rs"
                        ],
                        [
                            "concurrency_group" : "600",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "164",
                            "timeout" : "5000000000",
                            "host" : "limundo.com"
                        ],
                        [
                            "concurrency_group" : "640",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "150",
                            "timeout" : "5000000000",
                            "host" : "avto.net"
                        ],
                        [
                            "concurrency_group" : "630",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "156",
                            "timeout" : "5000000000",
                            "resolver" : "8.8.8.8",
                            "host" : "www.7c669de765.darknet.akostest.net"
                        ],
                        [
                            "concurrency_group" : "600",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "105",
                            "timeout" : "5000000000",
                            "host" : "24ur.com"
                        ],
                        [
                            "concurrency_group" : "610",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "110",
                            "timeout" : "5000000000",
                            "host" : "touch.darkspace.akostest.net"
                        ],
                        [
                            "concurrency_group" : "640",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "128",
                            "timeout" : "5000000000",
                            "host" : "najdi.si"
                        ],
                        [
                            "concurrency_group" : "600",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "162",
                            "timeout" : "5000000000",
                            "host" : "slovenskenovice.si"
                        ],
                        [
                            "concurrency_group" : "600",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "83",
                            "timeout" : "5000000000",
                            "host" : "apple.com"
                        ],
                        [
                            "concurrency_group" : "620",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "142",
                            "timeout" : "5000000000",
                            "resolver" : "8.8.8.8",
                            "host" : "bolha.com"
                        ],
                        [
                            "concurrency_group" : "630",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "143",
                            "timeout" : "5000000000",
                            "host" : "rtvslo.si"
                        ],
                        [
                            "concurrency_group" : "630",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "145",
                            "timeout" : "5000000000",
                            "host" : "www.63cae7b678.darknet.akostest.net"
                        ],
                        [
                            "concurrency_group" : "620",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "139",
                            "timeout" : "5000000000",
                            "host" : "tusmobil.si"
                        ],
                        [
                            "concurrency_group" : "600",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "86",
                            "timeout" : "5000000000",
                            "host" : "ftp.79e50d4485.com"
                        ],
                        [
                            "concurrency_group" : "600",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "89",
                            "timeout" : "5000000000",
                            "host" : "facebook.com"
                        ],
                        [
                            "concurrency_group" : "610",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "108",
                            "timeout" : "5000000000",
                            "host" : "wikipedia.org"
                        ],
                        [
                            "concurrency_group" : "610",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "109",
                            "timeout" : "5000000000",
                            "host" : "yahoo.com"
                        ],
                        [
                            "concurrency_group" : "610",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "113",
                            "timeout" : "5000000000",
                            "host" : "simobil.si"
                        ],
                        [
                            "concurrency_group" : "610",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "112",
                            "timeout" : "5000000000",
                            "host" : "telekom.si"
                        ],
                        [
                            "concurrency_group" : "640",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "129",
                            "timeout" : "5000000000",
                            "host" : "google.com"
                        ],
                        [
                            "concurrency_group" : "620",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "138",
                            "timeout" : "5000000000",
                            "host" : "microsoft.com"
                        ],
                        [
                            "concurrency_group" : "630",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "144",
                            "timeout" : "5000000000",
                            "host" : "youtube.com"
                        ],
                        [
                            "concurrency_group" : "640",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "130",
                            "timeout" : "5000000000",
                            "host" : "t-2.net"
                        ],
                        [
                            "concurrency_group" : "620",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "136",
                            "timeout" : "5000000000",
                            "host" : "amis.net"
                        ],
                        [
                            "concurrency_group" : "620",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "137",
                            "timeout" : "5000000000",
                            "host" : "telemach.si"
                        ],
                        [
                            "concurrency_group" : "640",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "MX",
                            "qos_test_uid" : "151",
                            "timeout" : "5000000000",
                            "host" : "gov.si"
                        ],
                        [
                            "concurrency_group" : "630",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "154",
                            "timeout" : "5000000000",
                            "host" : "akos-rs.si"
                        ],
                        [
                            "concurrency_group" : "620",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "155",
                            "timeout" : "5000000000",
                            "host" : "finance.si"
                        ],
                        [
                            "concurrency_group" : "600",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "82",
                            "timeout" : "5000000000",
                            "host" : "www.d070a426af.net"
                        ],
                        [
                            "concurrency_group" : "610",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "107",
                            "timeout" : "5000000000",
                            "host" : "twitter.com"
                        ],
                        [
                            "concurrency_group" : "640",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "AAAA",
                            "qos_test_uid" : "126",
                            "timeout" : "5000000000",
                            "host" : "facebook.com"
                        ],
                        [
                            "concurrency_group" : "640",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "AAAA",
                            "qos_test_uid" : "127",
                            "timeout" : "5000000000",
                            "host" : "google.com"
                        ],
                        [
                            "concurrency_group" : "630",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "146",
                            "timeout" : "5000000000",
                            "host" : "invalidname.5e2424b471.com"
                        ],
                        [
                            "concurrency_group" : "630",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "147",
                            "timeout" : "5000000000",
                            "host" : "amazon.com"
                        ],
                        [
                            "concurrency_group" : "630",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "AAAA",
                            "qos_test_uid" : "149",
                            "timeout" : "5000000000",
                            "host" : "youtube.com"
                        ],
                        [
                            "concurrency_group" : "640",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "AAAA",
                            "qos_test_uid" : "152",
                            "timeout" : "5000000000",
                            "host" : "wikipedia.org"
                        ],
                        [
                            "concurrency_group" : "610",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "153",
                            "timeout" : "5000000000",
                            "host" : "www.057b9714a8d3953bf22b.com"
                        ],
                        [
                            "concurrency_group" : "630",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "record" : "A",
                            "qos_test_uid" : "148",
                            "timeout" : "5000000000",
                            "host" : "siol.net"
                        ]
                    ],
                    "website" : [
                        [
                            "server_port" : "5235",
                            "qos_test_uid" : "159",
                            "timeout" : "10000000000",
                            "concurrency_group" : "500",
                            "url" : "https://www.akostest.net/kepler/",
                            "server_addr" : "172.104.182.115"
                        ]
                    ],
                    "http_proxy" : [
                        [
                            "download_timeout" : "10000000000",
                            "concurrency_group" : "400",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "qos_test_uid" : "160",
                            "conn_timeout" : "5000000000",
                            "url" : "https://www.akostest.net/qostest/reference05.jpg"
                        ],
                        [
                            "range" : "bytes=1000000-1004999",
                            "download_timeout" : "10000000000",
                            "concurrency_group" : "400",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "qos_test_uid" : "163",
                            "conn_timeout" : "5000000000",
                            "url" : "https://www.akostest.net/qostest/reference01.jpg"
                        ]
                    ],
                    "jitter" : [
                        [
                            "concurrency_group" : "10",
                            "call_duration" : "2000000000",
                            "server_addr" : "172.104.182.115",
                            "qos_test_uid" : "169",
                            "timeout" : "10000000000",
                            "out_port" : "7060",
                            "server_port" : "5235",
                            "in_port" : "7061"
                        ],
                        [
                            "concurrency_group" : "10",
                            "call_duration" : "2000000000",
                            "server_addr" : "172.104.182.115",
                            "qos_test_uid" : "169",
                            "timeout" : "10000000000",
                            "out_port" : "7060",
                            "server_port" : "5235",
                            "in_port" : "7061"
                        ],
                        [
                            "concurrency_group" : "10",
                            "call_duration" : "2000000000",
                            "server_addr" : "172.104.182.115",
                            "qos_test_uid" : "169",
                            "timeout" : "10000000000",
                            "out_port" : "7060",
                            "server_port" : "5235",
                            "in_port" : "7061"
                        ]
                    ],
                    "non_transparent_proxy" : [
                        [
                            "request" : "GET ",
                            "concurrency_group" : "300",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "qos_test_uid" : "84",
                            "timeout" : "5000000000",
                            "port" : "80"
                        ],
                        [
                            "request" : "GET / HTTR/7.9",
                            "concurrency_group" : "300",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "qos_test_uid" : "85",
                            "timeout" : "5000000000",
                            "port" : "22222"
                        ],
                        [
                            "request" : "GET ",
                            "concurrency_group" : "300",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "qos_test_uid" : "140",
                            "timeout" : "5000000000",
                            "port" : "44444"
                        ],
                        [
                            "request" : "GET / HTTR/7.9",
                            "concurrency_group" : "300",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "qos_test_uid" : "141",
                            "timeout" : "5000000000",
                            "port" : "80"
                        ],
                        [
                            "request" : "SMTP Transparent",
                            "concurrency_group" : "300",
                            "server_addr" : "172.104.182.115",
                            "server_port" : "5235",
                            "qos_test_uid" : "158",
                            "timeout" : "5000000000",
                            "port" : "25"
                        ]
                    ],
                    "voip" : [
                        [
                            "concurrency_group" : "10",
                            "call_duration" : "2000000000",
                            "server_addr" : "172.104.182.115",
                            "qos_test_uid" : "76",
                            "timeout" : "10000000000",
                            "out_port" : "5060",
                            "server_port" : "5235",
                            "in_port" : "5061"
                        ]
                    ],
                    "tcp" : [
                        [
                            "server_port" : "5235",
                            "out_port" : "143",
                            "qos_test_uid" : "116",
                            "timeout" : "5000000000",
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115"
                        ],
                        [
                            "server_port" : "5235",
                            "out_port" : "53",
                            "qos_test_uid" : "100",
                            "timeout" : "5000000000",
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115"
                        ],
                        [
                            "server_port" : "5235",
                            "out_port" : "25",
                            "qos_test_uid" : "90",
                            "timeout" : "5000000000",
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115"
                        ],
                        [
                            "server_port" : "5235",
                            "out_port" : "587",
                            "qos_test_uid" : "91",
                            "timeout" : "5000000000",
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115"
                        ],
                        [
                            "server_port" : "5235",
                            "out_port" : "993",
                            "qos_test_uid" : "92",
                            "timeout" : "5000000000",
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115"
                        ],
                        [
                            "server_port" : "5235",
                            "out_port" : "995",
                            "qos_test_uid" : "93",
                            "timeout" : "5000000000",
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115"
                        ],
                        [
                            "server_port" : "5235",
                            "out_port" : "5060",
                            "qos_test_uid" : "94",
                            "timeout" : "5000000000",
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115"
                        ],
                        [
                            "server_port" : "5235",
                            "out_port" : "9001",
                            "qos_test_uid" : "95",
                            "timeout" : "5000000000",
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115"
                        ],
                        [
                            "server_port" : "5235",
                            "out_port" : "554",
                            "qos_test_uid" : "96",
                            "timeout" : "5000000000",
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115"
                        ],
                        [
                            "server_port" : "5235",
                            "out_port" : "80",
                            "qos_test_uid" : "97",
                            "timeout" : "5000000000",
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115"
                        ],
                        [
                            "server_port" : "5235",
                            "out_port" : "21",
                            "qos_test_uid" : "98",
                            "timeout" : "5000000000",
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115"
                        ],
                        [
                            "server_port" : "5235",
                            "out_port" : "22",
                            "qos_test_uid" : "99",
                            "timeout" : "5000000000",
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115"
                        ],
                        [
                            "server_port" : "5235",
                            "out_port" : "6881",
                            "qos_test_uid" : "114",
                            "timeout" : "5000000000",
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115"
                        ],
                        [
                            "server_port" : "5235",
                            "out_port" : "465",
                            "qos_test_uid" : "117",
                            "timeout" : "5000000000",
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115"
                        ],
                        [
                            "server_port" : "5235",
                            "out_port" : "585",
                            "qos_test_uid" : "118",
                            "timeout" : "5000000000",
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115"
                        ],
                        [
                            "server_port" : "5235",
                            "out_port" : "110",
                            "qos_test_uid" : "115",
                            "timeout" : "5000000000",
                            "concurrency_group" : "200",
                            "server_addr" : "172.104.182.115"
                        ]
                    ]
                ],
                "error" : [
                    
                ]
            ]
        }
    }
}
