import SwiftUI

struct HUDOverlay: View {
    @ObservedObject var speechRecognizer: SpeechRecognizer
    @ObservedObject var npcSpeaker: NPCSpeaker

    var body: some View {
        VStack(spacing: 0) {
            // Model loading banner
            if !speechRecognizer.modelReady {
                Text("Chargement du modèle vocal…")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(.black.opacity(0.7), in: Capsule())
                    .padding(.top, 56)
            }

            Spacer()

            // Live transcript
            if !speechRecognizer.transcript.isEmpty {
                TranscriptView(text: speechRecognizer.transcript)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Transcription in-progress hint
            if speechRecognizer.isTranscribing {
                Text("Transcription en cours…")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.bottom, 8)
            }

            // Control bar
            HStack(spacing: 28) {
                // Replay NPC greeting (test control for Phase 0)
                Button {
                    npcSpeaker.speak("Bonjour ! Vous avez l'air perdu. Puis-je vous aider ?")
                } label: {
                    Label("NPC", systemImage: "person.wave.2.fill")
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 11)
                        .background(.blue.opacity(0.88), in: Capsule())
                        .foregroundStyle(.white)
                }
                .disabled(npcSpeaker.isSpeaking)

                MicButton(speechRecognizer: speechRecognizer)
            }
            .padding(.bottom, 44)
        }
        .animation(.easeInOut(duration: 0.25), value: speechRecognizer.transcript)
    }
}
