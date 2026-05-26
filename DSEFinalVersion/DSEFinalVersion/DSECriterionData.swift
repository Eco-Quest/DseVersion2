import Foundation

class DSEPronunciationDeliveryData {
    var score: Double
    var band: DSEBand
    var avg_volume: Double
    var sd_volume: Double
    var stabilityScore: Double
    var volumeStabilityText: String
    var avg_pace: Double
    var sd_pace: Double
    var filler_words_count: Int
    var filler_words_used: [String]
    
    init(
        score: Double = 0,
        band: DSEBand = .unclassified,
        avg_volume: Double = 0,
        sd_volume: Double = 0,
        stabilityScore: Double = 0,
        volumeStabilityText: String = "",
        avg_pace: Double = 0,
        sd_pace: Double = 0,
        filler_words_count: Int = 0,
        filler_words_used: [String] = []
    ) {
        self.score = score
        self.band = band
        self.avg_volume = avg_volume
        self.sd_volume = sd_volume
        self.stabilityScore = stabilityScore
        self.volumeStabilityText = volumeStabilityText
        self.avg_pace = avg_pace
        self.sd_pace = sd_pace
        self.filler_words_count = filler_words_count
        self.filler_words_used = filler_words_used
    }
}

class DSECommunicationStrategiesData {
    var score: Double
    var band: DSEBand
    var emotionPercentages: [String: Double]
    var eyeContactPercentages: [String: Double]
    
    init(
        score: Double = 0,
        band: DSEBand = .unclassified,
        emotionPercentages: [String: Double] = [:],
        eyeContactPercentages: [String: Double] = [:]
    ) {
        self.score = score
        self.band = band
        self.emotionPercentages = emotionPercentages
        self.eyeContactPercentages = eyeContactPercentages
    }
}

class DSEVocabularyLanguagePatternsData {
    var score: Double?
    var band: DSEBand?
    
    init(
        score: Double? = nil,
        band: DSEBand? = nil
    ) {
        self.score = score
        self.band = band
    }
}

class DSEIdeasOrganizationData {
    var score: Double?
    var band: DSEBand?
    
    init(
        score: Double? = nil,
        band: DSEBand? = nil
    ) {
        self.score = score
        self.band = band
    }
}
