//
//  RMBTClientTests.swift
//  RMBTClientTests
//
//  Created by Sergey Glushchenko on 3/10/18.
//

import XCTest
@testable import RMBTClient

class RMBTClientTests: XCTestCase {
    
    let workerQueue = DispatchQueue.main
    
    let baseUrl = "https://ont.specure.com/RMBTControlServer"
    let mapServerUrl = "https://ont.specure.com/RMBTControlServer"
    
    var testToken: String = ""
    
    override func setUp() {
        super.setUp()
        
        // Override control servers configuration
        
        RMBTConfig.sharedInstance.configNewCS(server: self.baseUrl)
        RMBTConfig.sharedInstance.configNewCS_IPv4(server: self.baseUrl)
        RMBTConfig.sharedInstance.configNewCS_IPv6(server: self.baseUrl)
        // Map server
        RMBTConfig.sharedInstance.configNewMapServer(server: self.mapServerUrl)
        //
        RMBTConfig.sharedInstance.RMBT_VERSION_NEW = false
        
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testRequestSettings() {
        let expectation = self.expectation(description: "testRequestSettings")
        
        var requestError: Error? = nil
        RMBTConfig.updateSettings(success: {
            expectation.fulfill()
        }, error: { error in
            requestError = error
            expectation.fulfill()
        })
        
        XCTAssertNil(requestError, "Error must be nil")
        waitForExpectations(timeout: 120, handler: nil)
    }
    
    func testRequestMeasurement_Old() {
        let expectation = self.expectation(description: "")
        
        
        
        let speedMeasurementRequest = SpeedMeasurementRequest()
        speedMeasurementRequest.version = "0.3" // TODO: duplicate?
        speedMeasurementRequest.time = UInt64.currentTimeMillis()
        speedMeasurementRequest.testCounter = RMBTSettings.sharedSettings.testCounter
        
        if let l = RMBTLocationTracker.sharedTracker.location {
            let geoLocation = GeoLocation(location: l)
            
            speedMeasurementRequest.geoLocation = geoLocation
        }
        
        let controlServer = ControlServer.sharedControlServer
        
        let speedMeasurementRequestOld = SpeedMeasurementRequest_Old()
        
        speedMeasurementRequestOld.testCounter = RMBTSettings.sharedSettings.testCounter
        //
        if let serverId = RMBTConfig.sharedInstance.measurementServer?.id as? UInt64 {
            speedMeasurementRequestOld.measurementServerId = serverId
        } else {
            // If Empty fiels id server -> sets defaults
            // speedMeasurementRequestOld.measurementServerId = RMBTConfig.sharedInstance.defaultMeasurementServerId
        }
        
        
        if let l = RMBTLocationTracker.sharedTracker.location {
            let geoLocation = GeoLocation(location: l)
            
            speedMeasurementRequestOld.geoLocation = geoLocation
        }
        
        var requestError: Error? = nil
        // workaround - nasty :(
        
        RMBTConfig.updateSettings(success: {
            controlServer.requestSpeedMeasurement_Old(speedMeasurementRequestOld, success: { response in
                self.workerQueue.async {
                    let r = SpeedMeasurementResponse()
                    r.clientRemoteIp = response.clientRemoteIp
                    r.duration = response.duration
                    r.pretestDuration = response.pretestDuration
                    r.numPings = Int(response.numPings)!
                    r.numThreads = Int(response.numThreads)!
                    r.testToken = response.testToken
                    r.testUuid = response.testUuid
                    
                    let measure = TargetMeasurementServer()
                    measure.port = response.port?.intValue
                    measure.address = response.serverAddress
                    measure.name = response.serverName
                    measure.encrypted = response.serverEncryption
                    measure.uuid = response.testUuid
                    
                    r.add(details:measure)
                    expectation.fulfill()
                }
            }) { error in
                self.workerQueue.async {
                    requestError = error
                    expectation.fulfill()
                }
            }
        }, error: { error in
            requestError = error
            expectation.fulfill()
        })
        
        
        
        waitForExpectations(timeout: 120, handler: nil)
        
        XCTAssertNil(requestError, "Error must be nil")
    }
    
    func params(for key: String, in objectives: [String: [[String: Any]]]) -> [QOSTestParameters]? {
        for objective in objectives {
            if objective.key == key {
                return objective.value.map({ (dictionary) -> QOSTestParameters in
                    return dictionary as QOSTestParameters
                })
            }
        }
        return nil
    }
    
    ///
    private func getControlConnection(_ qosTest: QOSTest) -> QOSControlConnection {
        // determine control connection
        let controlConnectionKey: String = "\(qosTest.serverAddress)_\(qosTest.serverPort)"
        
        // TODO: make instantiation of control connection synchronous with locks!
        var conn: QOSControlConnection! = nil
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
            
//            controlConnectionMap[controlConnectionKey] = conn
        } else {
            Log.logger.debug("\(controlConnectionKey): control connection already opened")
        }
        
        if !conn.connected {
            // reconnect
            _ = conn.connect(qosTest.serverAddress, onPort: qosTest.serverPort)
        }
        
        return conn
    }
    
    func testRequestQosMeasurement() {
        let expectation = self.expectation(description: "")
        
        let controlServer = ControlServer.sharedControlServer
        
        var requestError: Error? = nil
        var resultResponse: QosMeasurmentResponse? = nil
        
        let speedMeasurementRequestOld = SpeedMeasurementRequest_Old()
        
        speedMeasurementRequestOld.testCounter = RMBTSettings.sharedSettings.testCounter
        //
        if let serverId = RMBTConfig.sharedInstance.measurementServer?.id as? UInt64 {
            speedMeasurementRequestOld.measurementServerId = serverId
        } else {
            // If Empty fiels id server -> sets defaults
            // speedMeasurementRequestOld.measurementServerId = RMBTConfig.sharedInstance.defaultMeasurementServerId
        }
        
        
        if let l = RMBTLocationTracker.sharedTracker.location {
            let geoLocation = GeoLocation(location: l)
            
            speedMeasurementRequestOld.geoLocation = geoLocation
        }
        
        var concurentGroups: [UInt] = []
        
        RMBTConfig.updateSettings(success: {
            controlServer.requestSpeedMeasurement_Old(speedMeasurementRequestOld, success: { response in
                self.workerQueue.async {
                    let r = SpeedMeasurementResponse.createAndFill(from: response)
                    self.testToken = r.testToken!
                    controlServer.requestQosMeasurement(r.testUuid, success: { [weak self] response in
                        let key = "jitter"
                        if let objectives = response.objectives,
                            let objectiveParams = self?.params(for: key, in: objectives) {
                            for params in objectiveParams {
                                if let qosTest = QOSFactory.createQOSTest(key, params: params) {
                                    concurentGroups.append(qosTest.concurrencyGroup)
                                    // get previously opened control connection
                                    let controlConnection = self?.getControlConnection(qosTest) // blocking if new connection has to be established
                                    let speedtestStartTime: UInt64 = UInt64(Date().timeIntervalSince1970)
                                    // get test executor
                                    if let testExecutor = QOSFactory.createTestExecutor(qosTest, controlConnection: controlConnection!, delegateQueue: self!.workerQueue, speedtestStartTime: speedtestStartTime) {
                                        // TODO: which queue?
                                        
                                        // set test token (TODO: IMPROVE)
                                        testExecutor.setCurrentTestToken(self?.testToken ?? "")
                                        
                                        if testExecutor.needsControlConnection() {
                                            // set control connection timeout (TODO: compute better! (not all tests may use same control connection))
                                            Log.logger.debug("setting control connection timeout to \(nsToMs(qosTest.timeout)) ms")
                                            controlConnection?.setTimeout(qosTest.timeout)
                                            
                                            // TODO: DETERMINE IF TEST NEEDS CONTROL CONNECTION
                                            // IF IT NEEDS IT, AND CONTROL CONNECTION CONNECT FAILED THEN SKIP THIS TEST AND DON'T SEND RESULT TO SERVER
                                            if !(controlConnection?.connected)! {
                                                // don't do this test
                                                Log.logger.info("skipping test because it needs control connection but we don't have this connection. \(qosTest)")
                                                
                                                self?.workerQueue.sync {
                                                    XCTAssert(false, "no result because test didn't run")
                                                    resultResponse = response
                                                    expectation.fulfill()
                                                }
                                                
                                                continue
                                            }
                                        }
                                        
                                        Log.logger.debug("starting execution of test: \(qosTest)")
                                        
                                        // execute test
                                        self?.workerQueue.async {
                                            testExecutor.execute { (testResult: QOSTestResult) in
                                                
                                                self?.workerQueue.async {
                                                    print("result")
                                                    print(testResult)
                                                    resultResponse = response
                                                    expectation.fulfill()
//                                                    self.qosTestFinishedWithResult(testResult.testType, withTestResult: testResult)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            
                        }
                        else {
                            expectation.fulfill()
                        }
                    }) { [weak self] error in
                        requestError = error
                        expectation.fulfill()
                    }
                }
            }) { error in
                self.workerQueue.async {
                    requestError = error
                    expectation.fulfill()
                }
            }
        }, error: { error in
            requestError = error
            expectation.fulfill()
        })
    
        waitForExpectations(timeout: 120, handler: nil)
        
        XCTAssertNil(requestError, "Error must be nil")
        XCTAssertNotNil(resultResponse, "Error must be not nil")
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
