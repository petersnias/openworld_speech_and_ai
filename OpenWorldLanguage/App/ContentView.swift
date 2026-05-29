import SwiftUI

struct ContentView: View {
    @StateObject private var speechRecognizer = SpeechRecognizer()
    @StateObject private var npcSpeaker = NPCSpeaker()

    var body: some View {
        ZStack {
            ARViewContainer(npcSpeaker: npcSpeaker)
                .ignoresSafeArea()
            HUDOverlay(speechRecognizer: speechRecognizer, npcSpeaker: npcSpeaker)
        }
        .onAppear {
            AudioSessionManager.shared.configure()
        }
    }
}
