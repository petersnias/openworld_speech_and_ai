import Foundation

// Matches a French transcript against a list of intents using keyword lookup.
// Both the transcript and keywords are normalized (lowercase, diacritics stripped)
// before comparison so accents in learner input don't cause missed matches.
final class IntentResolver {
    func resolve(transcript: String, against intents: [DialogueIntent]) -> String? {
        let normalized = normalize(transcript)
        for intent in intents {
            for keyword in intent.keywords where normalized.contains(keyword) {
                return intent.id
            }
        }
        return nil
    }

    private func normalize(_ text: String) -> String {
        text.lowercased()
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr-FR"))
    }
}
