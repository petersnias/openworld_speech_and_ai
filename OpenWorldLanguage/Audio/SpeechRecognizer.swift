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
    @Published var isWarmingUp: Bool = false
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
            // Warm up the ANE compilation graph before the user's first utterance.
            // Without this, Core ML JIT-compiles on the first real transcribe() call, causing
            // a ~20s cold-start stall. Warmup moves that cost to app launch instead.
            await warmUpANE()
            modelReady = true
        } catch {
            print("[SpeechRecognizer] WhisperKit load failed: \(error)")
        }
    }

    private func warmUpANE() async {
        guard let whisperKit else { return }
        isWarmingUp = true
        defer { isWarmingUp = false }
        let warmupURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("owlang_warmup.wav")
        do {
            try writeSilentWAV(to: warmupURL, durationSeconds: 0.5)
            var options = DecodingOptions()
            options.language = "fr"
            options.task = .transcribe
            _ = try? await whisperKit.transcribe(audioPath: warmupURL.path, decodeOptions: options)
        } catch {
            print("[SpeechRecognizer] ANE warmup failed: \(error)")
        }
    }

    /// Writes a mono 16 kHz WAV file of silence — the minimum valid input for WhisperKit warmup.
    private func writeSilentWAV(to url: URL, durationSeconds: Double) throws {
        let sampleRate: Double = 16_000
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!
        let frameCount = AVAudioFrameCount(sampleRate * durationSeconds)
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)!
        // Explicitly zero the channel data so there is no undefined noise
        if let channelData = buffer.floatChannelData {
            memset(channelData[0], 0, Int(frameCount) * MemoryLayout<Float>.size)
        }
        buffer.frameLength = frameCount
        let file = try AVAudioFile(forWriting: url, settings: format.settings)
        try file.write(from: buffer)
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
