import Foundation

enum DSEBand: String, CaseIterable {
    case unclassified = "U"
    case level1 = "1"
    case level2 = "2"
    case level3 = "3"
    case level4 = "4"
    case level5 = "5"
    case level6 = "6"
    case level7 = "7"
    case level5Star = "5*"
    case level5DoubleStar = "5**"
}

enum DSECriterionType: String, CaseIterable {
    case pronunciationDelivery = "Pronunciation & Delivery"
    case communicationStrategies = "Communication Strategies"
    case vocabularyLanguagePatterns = "Vocabulary & Language Patterns"
    case ideasOrganization = "Ideas & Organization"
    
    var displayName: String {
        switch self {
        case .pronunciationDelivery:
            return "發音與表達"
        case .communicationStrategies:
            return "溝通策略"
        case .vocabularyLanguagePatterns:
            return "詞彙與語言運用"
        case .ideasOrganization:
            return "內容與組織"
        }
    }
}
