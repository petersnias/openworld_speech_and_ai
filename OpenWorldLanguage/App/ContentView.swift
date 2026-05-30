import SwiftUI

struct ContentView: View {
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var npcSpeaker = NPCSpeaker()
    @StateObject private var dialogueEngine = DialogueEngine()
    @StateObject private var llmEngine = LLMEngine()
    @State private var gameStarted = false

    var body: some View {
        ZStack {
            if gameStarted {
                ARViewContainer(
                    onNPCPlaced: {
                        dialogueEngine.loadScenario("paris_directions_louvre")
                    },
                    npcIsSpeaking: npcSpeaker.isSpeaking
                )
                .ignoresSafeArea()
                .transition(.opacity)

                HUDOverlay(
                    speechRecognizer: speechRecognizer,
                    npcSpeaker: npcSpeaker,
                    dialogueEngine: dialogueEngine
                )
                .transition(.opacity)
            } else {
                StartScreenView(
                    speechRecognizer: speechRecognizer,
                    llmEngine: llmEngine,
                    onStart: {
                        withAnimation(.easeInOut(duration: 0.6)) {
                            gameStarted = true
                        }
                    }
                )
                .transition(.opacity)
            }
        }
        .onAppear {
            AudioSessionManager.shared.configure()
            dialogueEngine.configure(llmEngine: llmEngine)
        }
        // Relay each NPC speech request from the engine to the TTS speaker.
        .onChange(of: dialogueEngine.pendingSpeech) { _, request in
            guard let request else { return }
            npcSpeaker.speak(request.text)
        }
        // Let the engine know the NPC has finished so it can open the mic.
        .onChange(of: npcSpeaker.isSpeaking) { _, isSpeaking in
            if !isSpeaking {
                dialogueEngine.npcFinishedSpeaking()
            }
        }
        // Feed completed transcriptions + word scores into the dialogue engine.
        .onChange(of: speechRecognizer.isTranscribing) { _, isTranscribing in
            if !isTranscribing, !speechRecognizer.transcript.isEmpty {
                dialogueEngine.processTranscript(
                    speechRecognizer.transcript,
                    scoredWords: speechRecognizer.scoredWords
                )
            }
        }
    }
}
