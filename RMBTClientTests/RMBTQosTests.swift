//
//  RMBTQosTests.swift
//  RMBTClientTests
//
//  Created by Sergey Glushchenko on 4/4/18.
//

import XCTest
import ObjectMapper

@testable import RMBTClient

class RMBTQosTests: XCTestCase {
    
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testDNSQosTest() {
        let expectation = self.expectation(description: "testDNSQosTest")
        let qosSettings = Mapper<QosMeasurmentResponse>().map(JSONObject: self.qosSettings)
        var results: QosMeasurementResultRequest? = nil
        var helper: RMBTQoSTestHelper? = RMBTQoSTestHelper(type: .VOIP, testToken: self.testToken)
        helper?.parseParameters(parameters: qosSettings!)
        helper?.completionHandler = { r in
            results = r as? QosMeasurementResultRequest
            expectation.fulfill()
        }
        helper?.startNextConcurencyGroup()
        
        waitForExpectations(timeout: 120, handler: nil)
        
        XCTAssert(results?.qosResultList?.count ?? 0 > 0)
        helper = nil
    }
    
    
    
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
