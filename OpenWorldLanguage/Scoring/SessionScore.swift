import Foundation

enum WordQuality {
    case good   // probability >= 0.80
    case fair   // probability 0.55 – 0.79
    case poor   // probability < 0.55
}

struct ScoredWord: Codable, Identifiable {
    // UUID is for SwiftUI identity only; excluded from Codable so decoding
    // a saved record doesn't need to restore it.
    var id: UUID = UUID()
    let word: String
    let probability: Float

    var quality: WordQuality {
        switch probability {
        case 0.80...: return .good
        case 0.55..<0.80: return .fair
        default: return .poor
        }
    }

    enum CodingKeys: String, CodingKey { case word, probability }
}

struct SessionScore: Codable, Identifiable {
    let id: UUID
    let date: Date
    let scenarioId: String
    let nodeAttempts: [String: Int]   // nodeId → total attempts at that node
    let scoredWords: [ScoredWord]     // every word from every turn in the session

    // Extra attempts = attempts beyond the first per node.
    // 0 extra → 3 stars (perfect), 1–2 extra → 2 stars, 3+ → 1 star.
    var extraAttempts: Int {
        nodeAttempts.values.reduce(0) { $0 + max(0, $1 - 1) }
    }

    var stars: Int {
        switch extraAttempts {
        case 0: return 3
        case 1...2: return 2
        default: return 1
        }
    }

    var avgPronunciationScore: Float {
        guard !scoredWords.isEmpty else { return 1.0 }
        return scoredWords.map { $0.probability }.reduce(0, +) / Float(scoredWords.count)
    }

    var lowConfidenceWords: [ScoredWord] {
        scoredWords
            .filter { $0.probability < 0.60 }
            .sorted { $0.probability < $1.probability }
    }
}
