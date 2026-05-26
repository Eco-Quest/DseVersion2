import Foundation

class DSEPerformance {
    var overallScore: Double
    var overallBand: DSEBand
    var overallComment: String
    var speakingTurns: Int
    var speakingTurnDetails: [DSESpeakingTurnData]
    var transcript: String
    var transcriptWordCount: Int
    var speakingDurationSeconds: Double
    var volumePoints: [DSEVolumeSample]
    var emotionCounts: [String: Int]
    var eyeContactCounts: [String: Int]
    var eyeContactLookAwaySeconds: [Int]
    
    var pronunciationDelivery: DSEPronunciationDeliveryData
    var communicationStrategies: DSECommunicationStrategiesData
    var vocabularyLanguagePatterns: DSEVocabularyLanguagePatternsData
    var ideasOrganization: DSEIdeasOrganizationData
    var llmFeedback: DSELLMFeedback?
    
    init(
        overallScore: Double = 0,
        overallBand: DSEBand = .unclassified,
        overallComment: String = "尚未完成 DSE 評分",
        speakingTurns: Int = 0,
        speakingTurnDetails: [DSESpeakingTurnData] = [],
        transcript: String = "",
        transcriptWordCount: Int = 0,
        speakingDurationSeconds: Double = 0,
        volumePoints: [DSEVolumeSample] = [],
        emotionCounts: [String: Int] = [:],
        eyeContactCounts: [String: Int] = [:],
        eyeContactLookAwaySeconds: [Int] = [],
        pronunciationDelivery: DSEPronunciationDeliveryData = DSEPronunciationDeliveryData(),
        communicationStrategies: DSECommunicationStrategiesData = DSECommunicationStrategiesData(),
        vocabularyLanguagePatterns: DSEVocabularyLanguagePatternsData = DSEVocabularyLanguagePatternsData(),
        ideasOrganization: DSEIdeasOrganizationData = DSEIdeasOrganizationData(),
        llmFeedback: DSELLMFeedback? = nil
    ) {
        self.overallScore = overallScore
        self.overallBand = overallBand
        self.overallComment = overallComment
        self.speakingTurns = speakingTurns
        self.speakingTurnDetails = speakingTurnDetails
        self.transcript = transcript
        self.transcriptWordCount = transcriptWordCount
        self.speakingDurationSeconds = speakingDurationSeconds
        self.volumePoints = volumePoints
        self.emotionCounts = emotionCounts
        self.eyeContactCounts = eyeContactCounts
        self.eyeContactLookAwaySeconds = eyeContactLookAwaySeconds
        self.pronunciationDelivery = pronunciationDelivery
        self.communicationStrategies = communicationStrategies
        self.vocabularyLanguagePatterns = vocabularyLanguagePatterns
        self.ideasOrganization = ideasOrganization
        self.llmFeedback = llmFeedback
    }
    
    func score(for criterion: DSECriterionType) -> Double {
        switch criterion {
        case .pronunciationDelivery:
            return pronunciationDelivery.score
        case .communicationStrategies:
            return communicationStrategies.score
        case .vocabularyLanguagePatterns:
            return vocabularyLanguagePatterns.score ?? llmFeedback?.vocabularyLanguagePatterns.score ?? 0
        case .ideasOrganization:
            return ideasOrganization.score ?? llmFeedback?.ideasOrganization.score ?? 0
        }
    }
    
    func band(for criterion: DSECriterionType) -> DSEBand {
        switch criterion {
        case .pronunciationDelivery:
            return pronunciationDelivery.band
        case .communicationStrategies:
            return communicationStrategies.band
        case .vocabularyLanguagePatterns:
            return vocabularyLanguagePatterns.band ?? llmFeedback?.vocabularyLanguagePatterns.band ?? .unclassified
        case .ideasOrganization:
            return ideasOrganization.band ?? llmFeedback?.ideasOrganization.band ?? .unclassified
        }
    }
    
    func eyeContactLookAwayStarts(windowSize: Int = 5) -> [Int] {
        guard windowSize > 0 else { return [] }
        let starts = eyeContactLookAwaySeconds.map { ($0 / windowSize) * windowSize }
        return Array(Set(starts)).sorted()
    }
    
    func feedback(for criterion: DSECriterionType) -> DSECriterionLLMFeedback? {
        llmFeedback?.item(for: criterion)
    }
    
    func applyLLMFeedback(_ feedback: DSELLMFeedback) {
        llmFeedback = feedback
        
        if let vocabularyScore = feedback.vocabularyLanguagePatterns.score {
            vocabularyLanguagePatterns.score = vocabularyScore
        }
        if let vocabularyBand = feedback.vocabularyLanguagePatterns.band {
            vocabularyLanguagePatterns.band = vocabularyBand
        }
        
        if let ideasScore = feedback.ideasOrganization.score {
            ideasOrganization.score = ideasScore
        }
        if let ideasBand = feedback.ideasOrganization.band {
            ideasOrganization.band = ideasBand
        }
    }
    
}
