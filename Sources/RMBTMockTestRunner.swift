class RMBTMockTestRunner: RMBTTestRunner {
    
    var isDownloadWasAdded: Bool = false
    var isUploadWasAdded: Bool = false
    
    var measuredThroughputs: [RMBTThroughput]!
    
    var totalUploadBytes: Int = 0
    var totalDownloadBytes: Int = 0
    
    override func testWorker(_ worker: RMBTTestWorker, didDownloadLength length: UInt64, atNanos nanos: UInt64) {

        if !isDownloadWasAdded {
            isDownloadWasAdded = true
            for i in 0..<3 {
                let bytes = 10000
                let timeStep = 250 * NSEC_PER_MSEC
                var time = 0
                for _ in 0..<28 {
                    time += Int(timeStep)
                    totalDownloadBytes += bytes
                    measuredThroughputs = speedMeasurementResult.addLength(UInt64(bytes), atNanos: UInt64(time), forThreadIndex: i)
                }
            }
        }
        
        if measuredThroughputs != nil {
            DispatchQueue.main.async {
                self.delegate?.testRunnerDidMeasureThroughputs((self.measuredThroughputs as NSArray?)!, inPhase: .down)
            }
        }
    }
    
    override func testWorker(_ worker: RMBTTestWorker, didUploadLength length: UInt64, atNanos nanos: UInt64) {
        
        if !isUploadWasAdded {
            isUploadWasAdded = true
            for i in 0..<3 {
                let bytes = 10000
                let timeStep = 250 * NSEC_PER_MSEC
                var time = 0
                for _ in 0..<28 {
                    time += Int(timeStep)
                    totalUploadBytes += bytes
                    measuredThroughputs = speedMeasurementResult.addLength(UInt64(bytes), atNanos: UInt64(time), forThreadIndex: i)
                }
            }
        }

        if measuredThroughputs != nil {
            DispatchQueue.main.async {
                self.delegate?.testRunnerDidMeasureThroughputs((self.measuredThroughputs as NSArray?)!, inPhase: .up)
            }
        }
    }
    
    override func resultObject() -> SpeedMeasurementResult {
        let result = super.resultObject()
        result.totalBytesUpload = totalUploadBytes
        result.totalBytesDownload = totalDownloadBytes
        return result
    }
}
