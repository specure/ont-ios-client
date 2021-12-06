//
//  GCDProgressTimer.swift
//  RMBTClient
//
//  Created by Sergey Glushchenko on 7/2/19.
//

class GCDProgressTimer {
    private var timer: DispatchSourceTimer?
    
    private var duration: Double
    private var progress: (_ percent: Float) -> Void
    private var complete: (_ timer: GCDProgressTimer) -> Void
    
    private var progressStartedAtNanos: UInt64 = 0
    private var progressDurationNanos: UInt64 = 0

    fileprivate let timerQueue: DispatchQueue = DispatchQueue(label: "com.specure.nettest.progress.timer", attributes: .concurrent)

    init(with duration: Double, progress: @escaping (_ percent: Float) -> Void = { _ in }, complete: @escaping (_ timer: GCDProgressTimer) -> Void) {
        self.duration = duration
        self.progress = progress
        self.complete = complete
    }

    deinit {
        defer {
            stop()
        }
    }
    
    ///
    func start() {
        stop() // stop any previous timer
            
        // start new timer
        timer = createTimer(duration, timerQueue: timerQueue, progress: progress) { [weak self] in
            guard let `self` = self else { return }
            self.complete(self)
            self.stop()
        }
        
        timer?.resume()
    }
    
    ///
    func stop() {
        if timer != nil {
            timer?.cancel()
        }
        
        timer = nil
    }
    
    ///
    private func createTimer(_ duration: Double, timerQueue: DispatchQueue, progress: @escaping (_ percent: Float) -> Void = { _ in }, complete: @escaping () -> Void) -> DispatchSourceTimer {
        progressStartedAtNanos = RMBTCurrentNanos()
        progressDurationNanos = UInt64(duration * Double(NSEC_PER_SEC))
        
        let timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: 0), queue: DispatchQueue.global(qos: .default))
        
        timer.schedule(deadline: DispatchTime.now(),
                       repeating: RMBTTestRunnerProgressUpdateInterval,
                       leeway: DispatchTimeInterval.seconds(60 * 10)) // 10 minutes
        timer.setEventHandler { [weak self] in
            guard let `self` = self else { return }
            let elapsedNanos: Int64 = (Int64(RMBTCurrentNanos()) - Int64(self.progressStartedAtNanos ))
            
            if elapsedNanos > self.progressDurationNanos {
                if self.timer != nil {
                    self.timer?.cancel()
                }
                self.timer = nil
                
                DispatchQueue.main.async {
                    complete()
                }
            } else {
                let p = Float(elapsedNanos) / Float(self.progressDurationNanos)
                assert(p <= 1.0, "Invalid percentage")
                DispatchQueue.main.async {
                    progress(p)
                }
            }
        }
        
        return timer
    }
}
