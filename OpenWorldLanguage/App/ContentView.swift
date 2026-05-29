import SwiftUI

struct ContentView: View {
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var npcSpeaker = NPCSpeaker()
    @State private var gameStarted = false

    var body: some View {
        ZStack {
            if gameStarted {
                ARViewContainer(npcSpeaker: npcSpeaker)
                    .ignoresSafeArea()
                    .transition(.opacity)
                HUDOverlay(speechRecognizer: speechRecognizer, npcSpeaker: npcSpeaker)
                    .transition(.opacity)
            } else {
                StartScreenView(speechRecognizer: speechRecognizer) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        gameStarted = true
                    }
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            AudioSessionManager.shared.configure()
        }
    }
}
