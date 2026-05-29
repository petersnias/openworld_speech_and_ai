import AVFoundation
import Combine

/// Speaks NPC dialogue in French using on-device AVSpeechSynthesizer.
/// Rate is set slightly below default so learners can follow along.
/// Spatial audio from the NPC's AR position is a Phase 1 enhancement.
@MainActor
final class NPCSpeaker: NSObject, ObservableObject {
    @Published var isSpeaking: Bool = false

    private let synthesizer = AVSpeechSynthesizer()
    // Prefer the enhanced (neural) French voice when downloaded on device
    private let voice = AVSpeechSynthesisVoice(language: "fr-FR")

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = 0.42       // ~20% slower than default — comfortable for learners
        utterance.pitchMultiplier = 1.05
        utterance.volume = 1.0
        synthesizer.speak(utterance)
        isSpeaking = true
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
}

extension NPCSpeaker: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor in self.isSpeaking = false }
    }
}
