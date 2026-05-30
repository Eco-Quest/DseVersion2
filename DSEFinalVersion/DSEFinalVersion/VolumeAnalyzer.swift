import AVFoundation
import Foundation

/// 使用者發言期間的聲量分析：累積 RMS，每 5 秒回傳窗口平均 dB（對齊 DSE 評分 30–70 區間）。
final class VolumeAnalyzer {
    static let sampleInterval: TimeInterval = 5.0
    static let silenceSpeechDecibels: Double = 5.0
    
    private let queue = DispatchQueue(label: "com.dse.volumeAnalyzer", qos: .userInitiated)
    private var windowRMSSamples: [Double] = []
    private var timer: DispatchSourceTimer?
    private var isRunning = false
    private var lastEmittedGridTimestamp: TimeInterval = -1
    
    /// 回傳目前discussion秒數
    var discussionElapsedProvider: (() -> TimeInterval)?
    
    var onPeriodicAverage: ((Double, TimeInterval) -> Void)?
    
    private(set) var latestDecibel: Double = 0
    
    func start() {
        queue.async {
            self.stopLocked()
            self.windowRMSSamples.removeAll(keepingCapacity: true)
            self.latestDecibel = 0
            self.lastEmittedGridTimestamp = -1
            self.isRunning = true
            self.flushWindowLocked()
            self.startTimerLocked()
        }
    }
    
    func stop() {
        queue.async {
            self.flushWindowLocked()
            self.stopLocked()
        }
    }
    
    func ingest(buffer: AVAudioPCMBuffer) {
        guard let rms = Self.rms(from: buffer) else { return }
        ingestRMS(rms)
    }
    
    func ingestRMS(_ rms: Double) {
        let clamped = min(max(rms, 0), 1)
        queue.async {
            guard self.isRunning else { return }
            self.windowRMSSamples.append(clamped)
            self.latestDecibel = Self.speechDecibels(fromRMS: clamped)
        }
    }
    
    // MARK: - PCM / dB helpers
    
    /// 由 PCM buffer 計算 normalized RMS（0…1）
    static func rms(from buffer: AVAudioPCMBuffer) -> Double? {
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return nil }
        
        if let channelData = buffer.floatChannelData?[0] {
            var sumSquares: Double = 0
            for i in 0..<frameLength {
                let sample = Double(channelData[i])
                sumSquares += sample * sample
            }
            return sqrt(sumSquares / Double(frameLength))
        }
        
        if let channelData = buffer.int16ChannelData?[0] {
            var sumSquares: Double = 0
            for i in 0..<frameLength {
                let normalized = Double(channelData[i]) / 32768.0
                sumSquares += normalized * normalized
            }
            return sqrt(sumSquares / Double(frameLength))
        }
        
        return nil
    }
    
    /// 由 Int16 PCM `Data` 計算 normalized RMS
    static func rms(fromInt16Data data: Data) -> Double? {
        guard data.count >= 2 else { return nil }
        let sampleCount = data.count / 2
        var sumSquares: Double = 0
        
        data.withUnsafeBytes { bytes in
            let samples = bytes.bindMemory(to: Int16.self)
            for i in 0..<sampleCount {
                let normalized = Double(samples[i]) / 32768.0
                sumSquares += normalized * normalized
            }
        }
        
        return sqrt(sumSquares / Double(sampleCount))
    }
    
    /// 將 normalized RMS 映射為 DSE 評分使用的聲量 dB（約 30–70，正常口語約 40–55）
    static func speechDecibels(fromRMS rms: Double) -> Double {
        let safeRMS = max(rms, 1e-8)
        let dbfs = 20.0 * log10(safeRMS)
        // 參考 rms≈0.08 → 約 50 dB
        let mapped = 71.0 + dbfs
        return min(max(mapped, 0), 100)
    }
    
    // MARK: - Private
    
    private func startTimerLocked() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + Self.sampleInterval, repeating: Self.sampleInterval)
        timer.setEventHandler { [weak self] in
            self?.flushWindowLocked()
        }
        timer.resume()
        self.timer = timer
    }
    
    private func flushWindowLocked() {
        guard isRunning else { return }
        
        let averageDb: Double
        if windowRMSSamples.isEmpty {
            averageDb = Self.silenceSpeechDecibels
        } else {
            let avgRMS = windowRMSSamples.reduce(0, +) / Double(windowRMSSamples.count)
            averageDb = Self.speechDecibels(fromRMS: avgRMS)
            latestDecibel = averageDb
        }
        
        let gridTimestamp = Self.alignedDiscussionTimestamp(
            discussionElapsedProvider?() ?? 0
        )
        windowRMSSamples.removeAll(keepingCapacity: true)
        guard averageDb.isFinite else { return }
        guard gridTimestamp != lastEmittedGridTimestamp else { return }
        lastEmittedGridTimestamp = gridTimestamp
        
        let callback = onPeriodicAverage
        DispatchQueue.main.async {
            callback?(averageDb, gridTimestamp)
        }
    }
    
    static func alignedDiscussionTimestamp(_ elapsed: TimeInterval) -> TimeInterval {
        let safe = max(0, elapsed)
        return floor(safe / sampleInterval) * sampleInterval
    }
    
    private func stopLocked() {
        timer?.cancel()
        timer = nil
        isRunning = false
        lastEmittedGridTimestamp = -1
        windowRMSSamples.removeAll()
    }
}
