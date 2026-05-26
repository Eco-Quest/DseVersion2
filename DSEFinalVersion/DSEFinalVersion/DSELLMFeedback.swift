import Foundation

class DSECriterionLLMFeedback {
    var score: Double?
    var band: DSEBand?
    var justification: String?
    var strength: String?
    var weakness: String?
    var suggestion: String?
    
    init(
        score: Double? = nil,
        band: DSEBand? = nil,
        justification: String? = nil,
        strength: String? = nil,
        weakness: String? = nil,
        suggestion: String? = nil
    ) {
        self.score = score
        self.band = band
        self.justification = justification
        self.strength = strength
        self.weakness = weakness
        self.suggestion = suggestion
    }
}

class DSELLMFeedback {
    var pronunciationDelivery: DSECriterionLLMFeedback
    var communicationStrategies: DSECriterionLLMFeedback
    var vocabularyLanguagePatterns: DSECriterionLLMFeedback
    var ideasOrganization: DSECriterionLLMFeedback
    
    init(
        pronunciationDelivery: DSECriterionLLMFeedback = DSECriterionLLMFeedback(),
        communicationStrategies: DSECriterionLLMFeedback = DSECriterionLLMFeedback(),
        vocabularyLanguagePatterns: DSECriterionLLMFeedback = DSECriterionLLMFeedback(),
        ideasOrganization: DSECriterionLLMFeedback = DSECriterionLLMFeedback()
    ) {
        self.pronunciationDelivery = pronunciationDelivery
        self.communicationStrategies = communicationStrategies
        self.vocabularyLanguagePatterns = vocabularyLanguagePatterns
        self.ideasOrganization = ideasOrganization
    }
    
    func item(for criterion: DSECriterionType) -> DSECriterionLLMFeedback {
        switch criterion {
        case .pronunciationDelivery:
            return pronunciationDelivery
        case .communicationStrategies:
            return communicationStrategies
        case .vocabularyLanguagePatterns:
            return vocabularyLanguagePatterns
        case .ideasOrganization:
            return ideasOrganization
        }
    }
}
