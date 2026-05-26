import Foundation

class DSEScoreCalculator {
    enum LLMIntegrationError: LocalizedError {
        case invalidJSON(String)
        case emptyFeedback
        
        var errorDescription: String? {
            switch self {
            case .invalidJSON(let raw):
                return "LLM JSON 解析失敗: \(raw)"
            case .emptyFeedback:
                return "LLM 沒有返回可用的回饋內容"
            }
        }
    }
    
    func calculatePerformance(from input: DSEScoringInput) -> DSEPerformance {
        let pronunciationRawScore = calculatePronunciationDeliveryScore(
            avg_volume: input.avg_volume,
            sd_volume: input.sd_volume,
            speakingTurns: input.speakingTurns,
            avg_pace: input.avg_pace,
            sd_pace: input.sd_pace,
            filler_words_count: input.filler_words_count,
            speakingDurationSeconds: input.speakingDurationSeconds
        )
        let pronunciationBand = criterionBand(fromScore: pronunciationRawScore)
        let pronunciationScore = criterionScore(from: pronunciationBand)
        
        let communicationRawScore = calculateCommunicationStrategiesScore(
            eyeContactPercentages: input.eyeContactPercentages,
            emotionPercentages: input.emotionPercentages,
            speakingTurns: input.speakingTurns
        )
        let communicationBand = criterionBand(fromScore: communicationRawScore)
        let communicationScore = criterionScore(from: communicationBand)
        
        let pronunciationData = DSEPronunciationDeliveryData(
            score: pronunciationScore,
            band: pronunciationBand,
            avg_volume: input.avg_volume,
            sd_volume: input.sd_volume,
            stabilityScore: calculateIntonationScore(sd_volume: input.sd_volume),
            volumeStabilityText: volumeStabilityDescription(from: input.sd_volume),
            avg_pace: input.avg_pace,
            sd_pace: input.sd_pace,
            filler_words_count: input.filler_words_count,
            filler_words_used: input.filler_words_used
        )
        
        let communicationData = DSECommunicationStrategiesData(
            score: communicationScore,
            band: communicationBand,
            emotionPercentages: input.emotionPercentages,
            eyeContactPercentages: input.eyeContactPercentages
        )
        
        // Vocabulary / Ideas 由 ReportService LLM 回填
        let vocabularyData = DSEVocabularyLanguagePatternsData()
        let ideasData = DSEIdeasOrganizationData()
        
        let overallScore = calculateOverallScore(
            pronunciationBand: pronunciationData.band,
            communicationBand: communicationData.band,
            vocabularyBand: nil,
            ideasBand: nil
        )
        
        return DSEPerformance(
            overallScore: overallScore,
            overallBand: overallBand(forTotalScore: overallScore),
            overallComment: "",
            speakingTurns: input.speakingTurns,
            speakingTurnDetails: input.speakingTurnDetails,
            transcript: input.transcript,
            transcriptWordCount: input.transcriptWordCount,
            speakingDurationSeconds: input.speakingDurationSeconds,
            volumePoints: downsampledVolumePoints(input.volumeSamples),
            emotionCounts: input.emotionCounts,
            eyeContactCounts: input.eyeContactCounts,
            eyeContactLookAwaySeconds: input.eyeContactLookAwaySeconds,
            pronunciationDelivery: pronunciationData,
            communicationStrategies: communicationData,
            vocabularyLanguagePatterns: vocabularyData,
            ideasOrganization: ideasData
        )
    }
    
    // 本地計分，再呼叫 LLM 補充回饋及分數
    func calculatePerformanceWithLLM(
        from input: DSEScoringInput,
        messages: [ChatMessage],
        examText: String,
        partBResponses: [String] = [],
        completion: @escaping (Result<DSEPerformance, Error>) -> Void
    ) {
        let performance = calculatePerformance(from: input)
        let group = DispatchGroup()
        
        var llmFeedback = DSELLMFeedback()
        var hasAnyFeedback = false
        var firstError: Error?
        
        group.enter()
        ReportService.shared.generateVocabIdeasReport(
            from: messages,
            examText: examText,
            userSpeakingTurns: input.speakingTurns,
            totalSpeakingDuringSec: Int(input.speakingDurationSeconds.rounded()),
            partBResponses: partBResponses
        ) { result in
            defer { group.leave() }
            switch result {
            case .success(let raw):
                do {
                    let payload = try self.parseLLMResponse(raw)
                    llmFeedback.vocabularyLanguagePatterns = self.feedbackItem(from: payload["vocabulary_language"], allowScoreBand: true)
                    llmFeedback.ideasOrganization = self.feedbackItem(from: payload["ideas_organization"], allowScoreBand: true)
                    hasAnyFeedback = hasAnyFeedback
                        || self.hasMeaningfulFeedback(llmFeedback.vocabularyLanguagePatterns)
                        || self.hasMeaningfulFeedback(llmFeedback.ideasOrganization)
                } catch {
                    if firstError == nil { firstError = error }
                }
            case .failure(let error):
                if firstError == nil { firstError = error }
            }
        }
        
        group.enter()
        ReportService.shared.generatePronunCommReport(
            pronunciationData: performance.pronunciationDelivery,
            communicationData: performance.communicationStrategies,
            messages: messages,
            speakingTurns: input.speakingTurns,
            speakingDurationSeconds: input.speakingDurationSeconds
        ) { result in
            defer { group.leave() }
            switch result {
            case .success(let raw):
                do {
                    let payload = try self.parseLLMResponse(raw)
                    llmFeedback.pronunciationDelivery = self.feedbackItem(from: payload["pronunciation_delivery"], allowScoreBand: false)
                    llmFeedback.communicationStrategies = self.feedbackItem(from: payload["communication_strategies"], allowScoreBand: false)
                    hasAnyFeedback = hasAnyFeedback
                        || self.hasMeaningfulFeedback(llmFeedback.pronunciationDelivery)
                        || self.hasMeaningfulFeedback(llmFeedback.communicationStrategies)
                } catch {
                    if firstError == nil { firstError = error }
                }
            case .failure(let error):
                if firstError == nil { firstError = error }
            }
        }
        
        group.notify(queue: .main) {
            if hasAnyFeedback {
                performance.applyLLMFeedback(llmFeedback)
                self.recalculateOverall(for: performance)
                completion(.success(performance))
                return
            }
            
            if let error = firstError {
                completion(.failure(error))
            } else {
                completion(.failure(LLMIntegrationError.emptyFeedback))
            }
        }
    }
    
    // 只做分數整合，不處理 LLM 文字內容
    func recalculateOverall(for performance: DSEPerformance) {
        let score = calculateOverallScore(
            pronunciationBand: performance.band(for: .pronunciationDelivery),
            communicationBand: performance.band(for: .communicationStrategies),
            vocabularyBand: performance.band(for: .vocabularyLanguagePatterns),
            ideasBand: performance.band(for: .ideasOrganization)
        )
        
        performance.overallScore = score
        performance.overallBand = overallBand(forTotalScore: score)
        performance.overallComment = ""
    }
    
    func calculateOverallScore(
        pronunciationBand: DSEBand,
        communicationBand: DSEBand,
        vocabularyBand: DSEBand?,
        ideasBand: DSEBand?
    ) -> Double {
        let p = criterionScore(from: pronunciationBand)
        let c = criterionScore(from: communicationBand)
        let v = criterionScore(from: vocabularyBand ?? .unclassified)
        let i = criterionScore(from: ideasBand ?? .unclassified)
        return p + c + v + i
    }
    
    /** 
    計算Pronunciation Delivery 分數 
    分數由volume(avg_volume), intonation(sd_volume), fluency(sd_pace, avg_pace, fillers) 組成
    **/
    func calculatePronunciationDeliveryScore(
        avg_volume: Double,
        sd_volume: Double,
        speakingTurns: Int,
        avg_pace: Double,
        sd_pace: Double,
        filler_words_count: Int = 0,
        speakingDurationSeconds: Double? = nil
    ) -> Double {
        let volumeScore = calculateVolumeScore(avg_volume: avg_volume)
        let intonationScore = calculateIntonationScore(sd_volume: sd_volume)
        let fluencyScore = calculateFluencyScore(
            avg_pace: avg_pace,
            sd_pace: sd_pace,
            speakingTurns: speakingTurns,
            filler_words_count: filler_words_count,
            speakingDurationSeconds: speakingDurationSeconds
        )
        
        return normalizedScore(
            volumeScore * 0.20 +
            intonationScore * 0.35 +
            fluencyScore * 0.45
        )
    }
    
    func calculateVolumeScore(avg_volume: Double) -> Double {
        let volumeDb = max(0, avg_volume)
        let baseScore = 50.0
        
        if volumeDb >= 30, volumeDb <= 70 {
            return normalizedScore(baseScore + (50 - (abs(volumeDb - 50) / 20) * 50))
        }
        
        if volumeDb < 30 {
            return normalizedScore((volumeDb / 30) * 50)
        }
        
        return normalizedScore((70 / volumeDb) * 50)
    }
    
    
    func calculateIntonationScore(sd_volume: Double) -> Double {
        let sdDb = max(0, sd_volume)
        let baseScore = 50.0
        
        if sdDb >= 6, sdDb <= 16 {
            return normalizedScore(baseScore + (50 - (abs(sdDb - 11) / 5) * 50))
        }
        
        if sdDb < 6 {
            return normalizedScore((sdDb / 6) * 50)
        }
        
        return normalizedScore((16 / sdDb) * 50)
    }
    
    func calculateFluencyScore(
        avg_pace: Double,
        sd_pace: Double,
        speakingTurns: Int,
        filler_words_count: Int = 0,
        speakingDurationSeconds: Double? = nil
    ) -> Double {
        let safeAvgPace = max(0, avg_pace)
        
        // 底分計算
        let baseScore: Double
        if safeAvgPace >= 100 && safeAvgPace <= 150 {
            baseScore = 50 + (50 - (abs(safeAvgPace - 125) / 25) * 50)
        } else if safeAvgPace < 100 {
            baseScore = (safeAvgPace / 100) * 50
        } else {
            baseScore = (150 / safeAvgPace) * 50
        }
        
        // 扣分計算
        let stabilityPenalty = stabilityPenalty(sd_pace: sd_pace, speakingTurns: speakingTurns)
        let fillerPenalty = fillerPenalty(
            filler_words_count: filler_words_count,
            speakingDurationSeconds: speakingDurationSeconds
        )        
        return normalizedScore(baseScore * stabilityPenalty - fillerPenalty)
    }

    private func stabilityPenalty(sd_pace: Double, speakingTurns: Int) -> Double {
        let safeSD = max(0, sd_pace)
        let rawMultiplier: Double
        
        if safeSD >= 5 && safeSD <= 12 {
            rawMultiplier = 1.0
        } else if safeSD < 5 {
            rawMultiplier = max(0.80, safeSD / 5.0)
        } else {
            rawMultiplier = max(0.70, 12.0 / safeSD)
        }
        
        // Turns 太少就降低懲罰，避免過度扣分。
        let confidence: Double
        switch speakingTurns {
        case ...2: confidence = 0.35
        case 3...5: confidence = 0.70
        default: confidence = 1.0
        }
        
        return 1.0 - (1.0 - rawMultiplier) * confidence
    }
    
    private func fillerPenalty(
        filler_words_count: Int,
        speakingDurationSeconds: Double?
    ) -> Double {
        guard filler_words_count > 0 else { return 0 }
        let safeDuration = max(0, speakingDurationSeconds ?? 0)
        
        if safeDuration > 0 {
            let fillerRatePerMinute = Double(filler_words_count) / (safeDuration / 60.0)
            return min(20, fillerRatePerMinute * 2.0)
        }
        
        return min(12, Double(filler_words_count))
    }
    


    /** 
    計算Communication Strategies 分數 
    分數由Eye Contact(eyeContactPercentages), Emotion(emotionPercentages), Speaking Turns(speakingTurns) 組成
    **/
    func calculateCommunicationStrategiesScore(
        eyeContactPercentages: [String: Double],
        emotionPercentages: [String: Double],
        speakingTurns: Int
    ) -> Double {
        let scoreEyeContact = calculateEyeContactScore(eyeContactPercentages: eyeContactPercentages)
        let scoreEmotion = calculateEmotionScore(emotionPercentages: emotionPercentages)
        let turnsMultiplier = communicationTurnsMultiplier(speakingTurns: speakingTurns)
        
        let baseScore = scoreEyeContact * 0.60 + scoreEmotion * 0.40
        return normalizedScore(baseScore * turnsMultiplier)
    }
    
    private func calculateEyeContactScore(eyeContactPercentages: [String: Double]) -> Double {
        let center = eyeContactPercentages["center"] ?? 0
        let left = eyeContactPercentages["left"] ?? 0
        let right = eyeContactPercentages["right"] ?? 0
        let lookAway = eyeContactPercentages["lookAway"] ?? 0
        let noFace = eyeContactPercentages["noFace"] ?? 0
        
        let rawScore = (center / 80.0 * 100.0)
            - abs(left - right)
            - lookAway
            - (noFace * 5.0)
        
        return normalizedScore(rawScore)
    }
    
    private func calculateEmotionScore(emotionPercentages: [String: Double]) -> Double {
        let calm = emotionPercentages["calm"] ?? 0
        let joy = emotionPercentages["joy"] ?? 0
        let surprise = emotionPercentages["surprise"] ?? 0
        let angry = emotionPercentages["angry"] ?? 0
        let fear = emotionPercentages["fear"] ?? 0
        let disgust = emotionPercentages["disgust"] ?? 0
        let sad = emotionPercentages["sad"] ?? 0
        
        let positiveExpressive = min(joy + surprise, 30)
        let negative = angry + fear + disgust + sad
        
        let activeEmotions = emotionPercentages.values.filter { $0 > 5 }.count
        let varietyBonus = activeEmotions >= 3 ? 10.0 : 0.0
        
        let rawScore = (0.7 * calm)
            + (0.2 * positiveExpressive)
            + (0.1 * varietyBonus)
            - (0.6 * negative)
        
        return normalizedScore(rawScore)
    }
    
    private func communicationTurnsMultiplier(speakingTurns: Int) -> Double {
        switch speakingTurns {
        case ...1: return 0.55
        case 2: return 0.70
        case 3: return 0.85
        case 4...6: return 1.00
        case 7...8: return 0.9
        case 9...10: return 0.85
        default: return 0.75
        }
    }
    
    private func parseLLMResponse(_ raw: String) throws -> [String: Any] {
        guard let data = raw.data(using: .utf8),
              let object = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LLMIntegrationError.invalidJSON(raw)
        }
        return object
    }
    
    private func feedbackItem(from raw: Any?, allowScoreBand: Bool) -> DSECriterionLLMFeedback {
        guard let dict = raw as? [String: Any] else {
            return DSECriterionLLMFeedback()
        }
        
        let score: Double?
        let band: DSEBand?
        
        if allowScoreBand, let intScore = parseIntScore(dict["score"]) {
            score = Double(intScore)
            band = bandFromLevelScore(intScore)
        } else {
            score = nil
            band = nil
        }
        
        return DSECriterionLLMFeedback(
            score: score,
            band: band,
            justification: dict["justification"] as? String,
            strength: dict["strength"] as? String,
            weakness: dict["weakness"] as? String,
            suggestion: dict["suggestion"] as? String
        )
    }
    
    private func hasMeaningfulFeedback(_ item: DSECriterionLLMFeedback) -> Bool {
        item.score != nil
            || item.band != nil
            || !(item.justification ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !(item.strength ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !(item.weakness ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !(item.suggestion ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func parseIntScore(_ value: Any?) -> Int? {
        if let number = value as? NSNumber {
            let intValue = number.intValue
            return (0...7).contains(intValue) ? intValue : nil
        }
        if let string = value as? String {
            let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
            if let intValue = Int(trimmed), (0...7).contains(intValue) {
                return intValue
            }
        }
        return nil
    }
    
    // 將 LLM 返回的 0~7 整數分數轉為 band（僅用於 vocab/ideas 回填）
    private func bandFromLevelScore(_ score: Int) -> DSEBand {
        switch score {
        case 7: return .level7
        case 6: return .level6
        case 5: return .level5
        case 4: return .level4
        case 3: return .level3
        case 2: return .level2
        case 1: return .level1
        default: return .unclassified
        }
    }
    
    // 分項評分：0~100 -> U~7
    func criterionBand(fromScore rawScore: Double) -> DSEBand {
        let score = normalizedScore(rawScore)
        switch score {
        case 90...100: return .level7
        case 80..<90: return .level6
        case 70..<80: return .level5
        case 60..<70: return .level4
        case 40..<60: return .level3
        case 20..<40: return .level2
        case 10..<20: return .level1
        case 0..<10: return .unclassified
        default: return .unclassified
        }
    }
    
    // 分項最終分數：依 level convert到 0~7分
    func criterionScore(from band: DSEBand) -> Double {
        switch band {
        case .unclassified: return 0
        case .level1: return 1
        case .level2: return 2
        case .level3: return 3
        case .level4: return 4
        case .level5: return 5
        case .level6: return 6
        case .level7: return 7
        default: return 0
        }
    }
    
    // 總分評分：0-28 -> U~5**
    func overallBand(forTotalScore totalScore: Double) -> DSEBand {
        let score = min(max(totalScore, 0), 28)
        switch score {
        case 26...28: return .level5DoubleStar
        case 24..<26: return .level5Star
        case 22..<24: return .level5
        case 18..<22: return .level4
        case 12..<18: return .level3
        case 6..<12: return .level2
        case 3..<6: return .level1
        case 0..<3: return .unclassified
        default: return .unclassified
        }
    }
    
    private func volumeStabilityDescription(from standardDeviation: Double) -> String {
        switch standardDeviation {
        case ..<4:
            return "語調起伏偏少，整體較平淡"
        case ..<8:
            return "語調起伏適中，整體自然"
        case ..<12:
            return "語調有變化，整體可接受"
        case ..<20:
            return "語調波動偏明顯，偶有不穩"
        default:
            return "語調波動過大，可能影響穩定度"
        }
    }
    
    private func downsampledVolumePoints(_ points: [DSEVolumeSample], maxCount: Int = 120) -> [DSEVolumeSample] {
        guard points.count > maxCount else { return points }
        let step = max(1, points.count / maxCount)
        return stride(from: 0, to: points.count, by: step).map { points[$0] }
    }
    
    private func normalizedScore(_ rawScore: Double) -> Double {
        min(max(rawScore, 0), 100)
    }
    
}
