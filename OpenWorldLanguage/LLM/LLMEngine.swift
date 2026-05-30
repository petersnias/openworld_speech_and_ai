import Foundation

// Calls Claude Haiku via the Anthropic Messages API to generate short in-character
// French NPC responses when the scripted intent resolver finds no match and there
// is no scripted fallback node. Falls back to re-speaking the last NPC line when
// offline or when the API call fails.
@MainActor
final class LLMEngine: ObservableObject {
    // No model to download — ready as soon as the app launches.
    @Published var modelReady: Bool = true
    @Published var isLoading: Bool = false
    @Published var isGenerating: Bool = false

    private let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!

    private let systemPrompt = """
        Tu es un passant parisien sympathique qui aide un touriste à apprendre le français. \
        Le touriste essaie de parler français mais fait parfois des erreurs. \
        Réponds en 1 ou 2 phrases simples en français. Sois encourageant. \
        Ne passe jamais à l'anglais.
        """

    // MARK: - Generation

    /// Returns a short in-character French response, or `npcSpeech` on any failure.
    func generateNPCResponse(npcSpeech: String, userInput: String) async -> String {
        isGenerating = true
        defer { isGenerating = false }

        let userMessage = "\(npcSpeech)\n\nLe touriste a dit : \"\(userInput)\"\n\nTa réponse :"

        var request = URLRequest(url: apiURL, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.setValue(Config.anthropicAPIKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01",           forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json",     forHTTPHeaderField: "content-type")

        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 60,
            "system": systemPrompt,
            "messages": [["role": "user", "content": userMessage]]
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else {
            return npcSpeech
        }
        request.httpBody = httpBody

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            if let json       = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let content    = json["content"] as? [[String: Any]],
               let first      = content.first,
               let text       = first["text"] as? String {
                let reply = text.trimmingCharacters(in: .whitespacesAndNewlines)
                return reply.isEmpty ? npcSpeech : reply
            }
        } catch {
            print("[LLMEngine] API call failed: \(error.localizedDescription)")
        }

        return npcSpeech
    }
}
