import Foundation

struct DSEVolumeSample {
    let timestamp: TimeInterval
    let value: Double
}

struct DSESpeakingTurnData {
    let turnIndex: Int
    let wordCount: Int
    let durationSeconds: Double?
}

enum DSEEmotionLabel: String, CaseIterable {
    case joy
    case sad
    case calm
    case surprise
    case fear
    case disgust
    case angry
    
    var displayName: String {
        switch self {
        case .joy: return "Joy"
        case .sad: return "Sad"
        case .calm: return "Calm"
        case .surprise: return "Surprise"
        case .fear: return "Fear"
        case .disgust: return "Disgust"
        case .angry: return "Angry"
        }
    }
    
    static func key(from rawLabel: String) -> String? {
        let normalized = rawLabel.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "joy", "開心", "高興": return DSEEmotionLabel.joy.rawValue
        case "sad", "傷心", "難過": return DSEEmotionLabel.sad.rawValue
        case "calm", "自然": return DSEEmotionLabel.calm.rawValue
        case "surprise", "驚訝": return DSEEmotionLabel.surprise.rawValue
        case "fear", "害怕", "恐懼": return DSEEmotionLabel.fear.rawValue
        case "disgust", "厭惡": return DSEEmotionLabel.disgust.rawValue
        case "angry", "生氣", "憤怒": return DSEEmotionLabel.angry.rawValue
        default: return nil
        }
    }
}

enum DSEEyeContactLabel: String, CaseIterable {
    case center
    case left
    case right
    case lookAway
    case noFace
    
    var displayName: String {
        switch self {
        case .center: return "Center"
        case .left: return "Left"
        case .right: return "Right"
        case .lookAway: return "Look Away"
        case .noFace: return "No Face"
        }
    }
    
    static func key(from rawLabel: String) -> String? {
        let normalized = rawLabel.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch normalized {
        case "center", "中間", "正中": return DSEEyeContactLabel.center.rawValue
        case "left", "偏左": return DSEEyeContactLabel.left.rawValue
        case "right", "偏右": return DSEEyeContactLabel.right.rawValue
        case "lookaway", "太左/右", "太左", "太右": return DSEEyeContactLabel.lookAway.rawValue
        case "noface", "no face", "沒有臉": return DSEEyeContactLabel.noFace.rawValue
        default: return nil
        }
    }
}

struct DSEScoringInput {
    let speakingTurns: Int
    let speakingTurnDetails: [DSESpeakingTurnData]
    let transcript: String
    let transcriptWordCount: Int
    let speakingDurationSeconds: Double
    let avg_pace: Double
    let sd_pace: Double
    let volumeSamples: [DSEVolumeSample]
    let avg_volume: Double
    let sd_volume: Double
    let filler_words_count: Int
    let filler_words_used: [String]
    let emotionCounts: [String: Int]
    let emotionPercentages: [String: Double]
    let eyeContactCounts: [String: Int]
    let eyeContactPercentages: [String: Double]
    let eyeContactLookAwaySeconds: [Int]
}

final class DSEDataCollector {
    private static let defaultFillerWords: [String] = [
        "um", "uh", "er", "ah", "like", "you know", "i mean", "actually", "basically",
        "well", "so","anyway","literally","whatever"
    ]
    
    private(set) var speakingTurns: Int = 0
    private(set) var transcriptSegments: [String] = []
    private(set) var volumeSamples: [DSEVolumeSample] = []
    private(set) var emotionCounts: [String: Int] = [:]
    private(set) var eyeContactCounts: [String: Int] = [:]
    private(set) var eyeContactLookAwaySeconds: [Int] = []
    private(set) var fillerWords: [String] = []
    
    private var sessionStartAt: Date?
    private var speakingDurationSeconds: Double = 0
    private var speakingTurnWordCounts: [Int] = []
    private var speakingTurnDurations: [Double] = []
    
    func startSession() {
        resetSessionData()
        sessionStartAt = Date()
    }
    
    func endSession() {
        sessionStartAt = nil
    }
    
    func getDiscussionSeconds() -> TimeInterval? {
        guard let sessionStartAt else { return nil }
        return max(0, Date().timeIntervalSince(sessionStartAt))
    }
    
    func resetSessionData() {
        speakingTurns = 0
        transcriptSegments.removeAll()
        volumeSamples.removeAll()
        emotionCounts = resetEmotionCounts()
        eyeContactCounts = resetEyeContactCounts()
        eyeContactLookAwaySeconds.removeAll()
        speakingDurationSeconds = 0
        speakingTurnWordCounts.removeAll()
        speakingTurnDurations.removeAll()
        fillerWords = Self.defaultFillerWords
    }
    
    // (已使用)增加說話輪數 - 每次說話完 / transcript return後呼叫 incrementSpeakingTurns(by: 1)
    func incrementSpeakingTurns(by count: Int = 1) {
        guard count > 0 else { return }
        speakingTurns += count
    }
    
    // (已使用)增加文字段落 - 在每一次成功transcript後呼叫 appendTranscriptSegment(content)
    func appendTranscriptSegment(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        transcriptSegments.append(trimmed)
    }
    
    // (要用)增加聲量數據（dB）- 在每5秒呼叫一次 appendVolumeSample(45.3, 5)
    func appendVolumeSample(_ rawValue: Double, timestamp: TimeInterval? = nil) {
        guard rawValue.isFinite else { return }
        let sampleTimestamp: TimeInterval
        
        if let timestamp {
            sampleTimestamp = max(0, timestamp)
        } else if let sessionStartAt {
            sampleTimestamp = max(0, Date().timeIntervalSince(sessionStartAt))
        } else {
            sampleTimestamp = 0
        }
        
        volumeSamples.append(DSEVolumeSample(timestamp: sampleTimestamp, value: rawValue))
    }
    
    // (要用)增加情緒數據 - 在detect到表情後 appendEmotionCount("happy", count: 1)
    func appendEmotionCount(_ label: String, by count: Int = 1) {
        guard count > 0 else { return }
        guard let key = DSEEmotionLabel.key(from: label) else { return }
        emotionCounts[key, default: 0] += count
    }
    

    // (要用)增加眼神數據 - 在detect眼神後 appendEyeContactCount("center", count: 1)
    func appendEyeContactCount(_ label: String, by count: Int = 1) {
        guard count > 0 else { return }
        guard let key = DSEEyeContactLabel.key(from: label) else { return }
        eyeContactCounts[key, default: 0] += count
    }
    
    // (要用)增加眼神數據 - 在detect到Look away後 appendEyeContactLookAwayNow()
    func appendEyeContactLookAwayNow() {
        let second: Int
        if let sessionStartAt {
            second = max(0, Int(Date().timeIntervalSince(sessionStartAt)))
        } else {
            second = 0
        }
        appendEyeContactLookAwaySecond(second)
    }
    
    //(不用呼叫)已使用在appendEyeContactLookAwayNow()
    func appendEyeContactLookAwaySecond(_ second: Int) {
        guard second >= 0 else { return }
        if !eyeContactLookAwaySeconds.contains(second) {
            eyeContactLookAwaySeconds.append(second)
            eyeContactLookAwaySeconds.sort()
        }
    }

    
    func setSpeakingDuration(seconds: Double) {
        speakingDurationSeconds = max(0, seconds)
    }
    
    //(已使用)已使用在每次說話後 stopMicRecording(discardCurrentBuffer: false) 呼叫
    func addSpeakingDuration(seconds: Double) {
        guard seconds.isFinite else { return }
        speakingDurationSeconds += max(0, seconds)
    }
    
    // (已使用)每一輪的字數與時長, 在每一輪說話完後呼叫 appendSpeakingTurnData(wordCount: 10, durationSeconds: 10.5)
    func appendSpeakingTurnData(wordCount: Int, durationSeconds: Double?) {
        guard wordCount >= 0 else { return }
        speakingTurnWordCounts.append(wordCount)
        if let durationSeconds, durationSeconds > 0 {
            speakingTurnDurations.append(durationSeconds)
        }
    }
    
    func buildInputForScoring() -> DSEScoringInput {
        let cleanedVolumeSamples = volumeSamples
            .filter { $0.value.isFinite }
            .map { DSEVolumeSample(timestamp: max(0, $0.timestamp), value: $0.value) }
        
        let transcript = transcriptSegments.joined(separator: "\n")
        let transcriptWordCountFromText = transcript
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
        
        let transcriptWordCount = max(transcriptWordCountFromText, speakingTurnWordCounts.reduce(0, +))
        let effectiveDuration = speakingDurationSeconds > 0
            ? speakingDurationSeconds
            : (sessionStartAt.map { Date().timeIntervalSince($0) } ?? 0)
        let safeDuration = max(0, effectiveDuration)
        let avg_pace = safeDuration > 0 ? (Double(transcriptWordCount) / safeDuration) * 60 : 0
        
        let perTurnWPM = zip(speakingTurnWordCounts, speakingTurnDurations).map { words, seconds in
            guard seconds > 0 else { return 0.0 }
            return (Double(words) / seconds) * 60
        }
        let sd_pace = calculateStandardDeviation(perTurnWPM)
        
        let detailsCount = max(speakingTurnWordCounts.count, speakingTurnDurations.count)
        let speakingTurnDetails: [DSESpeakingTurnData] = (0..<detailsCount).map { index in
            let words = index < speakingTurnWordCounts.count ? speakingTurnWordCounts[index] : 0
            let duration = index < speakingTurnDurations.count ? speakingTurnDurations[index] : nil
            return DSESpeakingTurnData(
                turnIndex: index + 1,
                wordCount: words,
                durationSeconds: duration
            )
        }
        
        let volumeValues = cleanedVolumeSamples.map(\.value)
        let avg_volume = calculateMean(volumeValues)
        let sd_volume = calculateStandardDeviation(volumeValues)
        let fillerWordsMatch = detectFillerWords(in: transcript)
        let filler_words_count = fillerWordsMatch.count
        let filler_words_used = fillerWordsMatch.words
        
        let emotionPercentages = percentageMap(from: emotionCounts)
        let eyePercentages = percentageMap(from: eyeContactCounts)
        
        return DSEScoringInput(
            speakingTurns: max(0, speakingTurns),
            speakingTurnDetails: speakingTurnDetails,
            transcript: transcript,
            transcriptWordCount: transcriptWordCount,
            speakingDurationSeconds: safeDuration,
            avg_pace: avg_pace,
            sd_pace: sd_pace,
            volumeSamples: cleanedVolumeSamples,
            avg_volume: avg_volume,
            sd_volume: sd_volume,
            filler_words_count: filler_words_count,
            filler_words_used: filler_words_used,
            emotionCounts: emotionCounts,
            emotionPercentages: emotionPercentages,
            eyeContactCounts: eyeContactCounts,
            eyeContactPercentages: eyePercentages,
            eyeContactLookAwaySeconds: eyeContactLookAwaySeconds.sorted()
        )
    }
    
    private func percentageMap(from counts: [String: Int]) -> [String: Double] {
        let total = counts.values.reduce(0, +)
        guard total > 0 else {
            return counts.mapValues { _ in 0 }
        }
        let totalDouble = Double(total)
        
        var result: [String: Double] = [:]
        for (key, count) in counts {
            result[key] = (Double(count) / totalDouble) * 100
        }
        return result
    }
    
    private func calculateMean(_ values: [Double]) -> Double {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / Double(values.count)
    }
    
    private func calculateStandardDeviation(_ values: [Double]) -> Double {
        guard values.count > 1 else { return 0 }
        let mean = calculateMean(values)
        let variance = values.reduce(0) { partialResult, value in
            let diff = value - mean
            return partialResult + diff * diff
        } / Double(values.count)
        return sqrt(variance)
    }
    
    //(不用呼叫)已使用在buildInputForScoring()
    private func detectFillerWords(in transcript: String) -> (count: Int, words: [String]) {
        guard !fillerWords.isEmpty else { return (0, []) }
        let lowerTranscript = transcript.lowercased()
        var total = 0
        var usedWords = Set<String>()
        
        for filler in fillerWords {
            let escaped = NSRegularExpression.escapedPattern(for: filler)
            let pattern = "\\b\(escaped)\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(lowerTranscript.startIndex..<lowerTranscript.endIndex, in: lowerTranscript)
                let matches = regex.numberOfMatches(in: lowerTranscript, options: [], range: range)
                if matches > 0 { usedWords.insert(filler) }
                total += matches
            }
        }
        
        return (total, usedWords.sorted())
    }
    
    private func resetEmotionCounts() -> [String: Int] {
        var result: [String: Int] = [:]
        for item in DSEEmotionLabel.allCases {
            result[item.rawValue] = 0
        }
        return result
    }
    
    private func resetEyeContactCounts() -> [String: Int] {
        var result: [String: Int] = [:]
        for item in DSEEyeContactLabel.allCases {
            result[item.rawValue] = 0
        }
        return result
    }
        
    func setFillerWords(_ words: [String]) {
        let normalized = words
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
        fillerWords = Array(Set(normalized)).sorted()
    }
    
    func resetFillerWordsToDefault() {
        fillerWords = Self.defaultFillerWords
    }
    
    func printCollectedDataSummary() {
        let input = buildInputForScoring()
        print("\n========== DSE Collected Data Summary ==========")
        print("Speaking turns: \(speakingTurns)")
        print("Speaking duration (sec): \(String(format: "%.1f", speakingDurationSeconds))")
        print("Transcript segments (\(transcriptSegments.count)):")
        for (index, segment) in transcriptSegments.enumerated() {
            print("  [\(index + 1)] \(segment)")
        }
        print("Full transcript:\n\(input.transcript)")
        print("Transcript word count: \(input.transcriptWordCount)")
        print("Volume samples (\(volumeSamples.count)): \(volumeSamples.map { "t=\(Int($0.timestamp))s dB=\(String(format: "%.1f", $0.value))" }.joined(separator: ", "))")
        print("Avg volume: \(String(format: "%.2f", input.avg_volume)), SD: \(String(format: "%.2f", input.sd_volume))")
        print("Emotion counts: \(emotionCounts)")
        print("Eye contact counts: \(eyeContactCounts)")
        print("Eye contact look away seconds: \(eyeContactLookAwaySeconds)")
        print("Speaking turn details: \(speakingTurnWordCounts.count) turns")
        for detail in input.speakingTurnDetails {
            let durationText = detail.durationSeconds.map { String(format: "%.1f", $0) } ?? "n/a"
            print("  Turn \(detail.turnIndex): words=\(detail.wordCount), duration=\(durationText)s")
        }
        print("Filler words: count=\(input.filler_words_count), used=\(input.filler_words_used)")
        print("Avg pace (WPM): \(String(format: "%.1f", input.avg_pace)), SD pace: \(String(format: "%.1f", input.sd_pace))")
        print("================================================\n")
    }

}
