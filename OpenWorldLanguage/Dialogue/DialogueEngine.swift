import Foundation

// Drives the conversation state machine for a single loaded scenario.
// ContentView owns the engine and wires NPC speech through .onChange(of: pendingSpeech).
@MainActor
final class DialogueEngine: ObservableObject {
    // HUD reads these to render speech bubble, hints, and completion screen.
    @Published var currentNPCSpeech: String = ""
    @Published var activeHints: [VocabularyHint] = []
    @Published var showHints: Bool = false
    @Published var awaitingUserInput: Bool = false
    @Published var scenarioComplete: Bool = false
    @Published var sessionScore: SessionScore? = nil
    // LLM state — HUD shows a "thinking" indicator while true.
    @Published var isAwaitingLLMResponse: Bool = false
    // True when the current NPC speech bubble came from the LLM (shows ✨ badge).
    @Published var lastSpeechWasLLMGenerated: Bool = false

    // ContentView observes this to call npcSpeaker.speak(). Using a value-typed
    // SpeechRequest with a UUID means .onChange fires even when the NPC repeats
    // the same line (e.g. a fallback loop returning to the same node).
    @Published var pendingSpeech: SpeechRequest?

    private var scenario: DialogueScenario?
    private var currentNodeId: String = ""
    private let resolver = IntentResolver()

    // Scoring accumulators — reset on each loadScenario / restartScenario.
    private var nodeAttempts: [String: Int] = [:]
    private var allScoredWords: [ScoredWord] = []

    // Injected by ContentView after both StateObjects are created.
    var llmEngine: LLMEngine?

    // MARK: - Public API

    func configure(llmEngine: LLMEngine) {
        self.llmEngine = llmEngine
    }

    func loadScenario(_ scenarioId: String) {
        guard let url = Bundle.main.url(forResource: scenarioId, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let loaded = try? JSONDecoder().decode(DialogueScenario.self, from: data) else {
            print("[DialogueEngine] Failed to load scenario '\(scenarioId)'")
            return
        }
        scenario = loaded
        resetSession()
        advanceTo(nodeId: loaded.startNode)
    }

    func restartScenario() {
        guard let scenarioId = scenario?.scenarioId else { return }
        loadScenario(scenarioId)
    }

    // Called by ContentView when npcSpeaker.isSpeaking flips to false.
    func npcFinishedSpeaking() {
        guard let scenario, let node = scenario.nodes[currentNodeId] else { return }
        awaitingUserInput = !(node.expectedIntents?.isEmpty ?? true)
    }

    // Called by ContentView after every completed WhisperKit transcription.
    func processTranscript(_ transcript: String, scoredWords: [ScoredWord] = []) {
        guard let scenario, !transcript.isEmpty,
              let node = scenario.nodes[currentNodeId],
              let intents = node.expectedIntents, !intents.isEmpty else { return }

        allScoredWords.append(contentsOf: scoredWords)
        nodeAttempts[currentNodeId, default: 0] += 1

        if let _ = resolver.resolve(transcript: transcript, against: intents) {
            showHints = false
            activeHints = []
            if let nextId = node.onMatch {
                advanceTo(nodeId: nextId)
            } else {
                completeScenario()
            }
        } else {
            let attempts = nodeAttempts[currentNodeId, default: 0]
            let threshold = node.hintAfterAttempts ?? 2
            if attempts >= threshold, let hints = node.hints, !hints.isEmpty {
                activeHints = hints
                showHints = true
            }
            if let fallbackId = node.onFallback {
                advanceTo(nodeId: fallbackId, preserveAttempts: true)
            } else if let llm = llmEngine, llm.modelReady {
                // LLM generates a contextual in-character response.
                isAwaitingLLMResponse = true
                awaitingUserInput = false
                Task {
                    let reply = await llm.generateNPCResponse(
                        npcSpeech: node.npcSpeech,
                        userInput: transcript
                    )
                    isAwaitingLLMResponse = false
                    lastSpeechWasLLMGenerated = true
                    currentNPCSpeech = reply
                    pendingSpeech = SpeechRequest(text: reply)
                }
            } else {
                // LLM not ready — re-speak the current NPC line.
                pendingSpeech = SpeechRequest(text: node.npcSpeech)
            }
        }
    }

    func dismissHints() {
        showHints = false
    }

    // MARK: - Private

    private func resetSession() {
        nodeAttempts = [:]
        allScoredWords = []
        scenarioComplete = false
        sessionScore = nil
        showHints = false
        activeHints = []
        awaitingUserInput = false
        currentNPCSpeech = ""
        isAwaitingLLMResponse = false
        lastSpeechWasLLMGenerated = false
    }

    private func advanceTo(nodeId: String, preserveAttempts: Bool = false) {
        guard let scenario, let node = scenario.nodes[nodeId] else { return }
        currentNodeId = nodeId
        currentNPCSpeech = node.npcSpeech
        awaitingUserInput = false
        lastSpeechWasLLMGenerated = false   // scripted node, never LLM
        if !preserveAttempts {
            showHints = false
            activeHints = []
        }
        if node.isTerminal == true {
            completeScenario()
        }
        pendingSpeech = SpeechRequest(text: node.npcSpeech)
    }

    private func completeScenario() {
        scenarioComplete = true
        let score = SessionScore(
            id: UUID(),
            date: Date(),
            scenarioId: scenario?.scenarioId ?? "",
            nodeAttempts: nodeAttempts,
            scoredWords: allScoredWords
        )
        sessionScore = score
        SessionStore.shared.save(score)
    }
}
