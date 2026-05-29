import AVFoundation
import WhisperKit
import Combine

/// Records audio via AVAudioRecorder, then transcribes offline using WhisperKit (whisper-small).
/// Uses French transcription mode — optimised for learner speech accuracy on A16 Neural Engine.
@MainActor
final class SpeechRecognizer: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var isTranscribing: Bool = false
    @Published var modelReady: Bool = false

    private var whisperKit: WhisperKit?
    private var audioRecorder: AVAudioRecorder?

    private let recordingURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("owlang_recording.m4a")

    init() {
        Task { await loadModel() }
    }

    // MARK: - Model loading

    private func loadModel() async {
        do {
            // whisper-small: ~500MB, strong French accuracy on A16 Neural Engine (~150ms latency)
            whisperKit = try await WhisperKit(model: "openai_whisper-small")
            modelReady = true
        } catch {
            print("[SpeechRecognizer] WhisperKit load failed: \(error)")
        }
    }

    // MARK: - Recording

    func startRecording() {
        guard !isRecording else { return }
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.record()
            isRecording = true
            transcript = ""
        } catch {
            print("[SpeechRecognizer] Recording start failed: \(error)")
        }
    }

    func stopAndTranscribe() async {
        guard isRecording else { return }
        audioRecorder?.stop()
        isRecording = false
        isTranscribing = true
        defer { isTranscribing = false }

        guard let whisperKit else {
            transcript = "[Model not ready]"
            return
        }

        do {
            var options = DecodingOptions()
            options.language = "fr"
            options.task = .transcribe
            let results = try await whisperKit.transcribe(
                audioPath: recordingURL.path,
                decodeOptions: options
            )
            transcript = results.first?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } catch {
            transcript = "[Transcription error]"
            print("[SpeechRecognizer] Transcription failed: \(error)")
        }
    }
}
