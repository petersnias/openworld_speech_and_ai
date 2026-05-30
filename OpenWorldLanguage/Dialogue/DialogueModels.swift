import Foundation

struct DialogueScenario: Decodable {
    let scenarioId: String
    let locale: String
    let startNode: String
    let nodes: [String: DialogueNode]

    enum CodingKeys: String, CodingKey {
        case scenarioId = "scenario_id"
        case locale
        case startNode = "start_node"
        case nodes
    }
}

struct DialogueNode: Decodable {
    let npcSpeech: String
    let expectedIntents: [DialogueIntent]?
    let onMatch: String?
    let onFallback: String?
    let hintAfterAttempts: Int?
    let hints: [VocabularyHint]?
    let isTerminal: Bool?

    enum CodingKeys: String, CodingKey {
        case npcSpeech = "npc_speech"
        case expectedIntents = "expected_intents"
        case onMatch = "on_match"
        case onFallback = "on_fallback"
        case hintAfterAttempts = "hint_after_attempts"
        case hints
        case isTerminal = "is_terminal"
    }
}

struct DialogueIntent: Decodable {
    let id: String
    let keywords: [String]
}

struct VocabularyHint: Decodable, Identifiable {
    let id: String
    let french: String
    let english: String
}

// Emitted by DialogueEngine each time the NPC should speak. UUID ensures
// .onChange fires even when the same line repeats (e.g. a fallback loop).
struct SpeechRequest: Equatable {
    let id = UUID()
    let text: String

    static func == (lhs: SpeechRequest, rhs: SpeechRequest) -> Bool { lhs.id == rhs.id }
}
