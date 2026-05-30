import Foundation

final class SessionStore {
    static let shared = SessionStore()

    private var sessions: [SessionScore] = []

    private let storageURL: URL = {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("sessions.json")
    }()

    private init() { load() }

    // MARK: - Public API

    func save(_ score: SessionScore) {
        sessions.append(score)
        persist()
    }

    func bestScore(for scenarioId: String) -> SessionScore? {
        sessions
            .filter { $0.scenarioId == scenarioId }
            .max { $0.stars < $1.stars }
    }

    // MARK: - Persistence

    private func load() {
        guard let data = try? Data(contentsOf: storageURL),
              let loaded = try? JSONDecoder().decode([SessionScore].self, from: data) else { return }
        sessions = loaded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        try? data.write(to: storageURL, options: .atomic)
    }
}
