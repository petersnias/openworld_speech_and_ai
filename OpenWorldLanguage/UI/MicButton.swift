import SwiftUI

struct MicButton: View {
    @ObservedObject var speechRecognizer: SpeechRecognizer
    var awaitingInput: Bool = true

    // Derived disabled state — mic is only active when the engine is waiting for user input.
    private var isDisabled: Bool {
        !speechRecognizer.modelReady || speechRecognizer.isTranscribing || !awaitingInput
    }

    var body: some View {
        Button {
            if speechRecognizer.isRecording {
                Task { await speechRecognizer.stopAndTranscribe() }
            } else {
                speechRecognizer.startRecording()
            }
        } label: {
            ZStack {
                Circle()
                    .fill(buttonColor)
                    .frame(width: 68, height: 68)
                    .shadow(color: .black.opacity(0.3), radius: 6, y: 3)
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundStyle(iconColor)
                    .symbolEffect(.pulse, isActive: speechRecognizer.isRecording)
            }
            // Subtle scale-down when disabled so the button reads as inactive at a glance.
            .scaleEffect(isDisabled ? 0.88 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.6), value: isDisabled)
            .animation(.easeInOut(duration: 0.2), value: speechRecognizer.isRecording)
        }
        .disabled(isDisabled)
    }

    private var buttonColor: Color {
        if !awaitingInput || speechRecognizer.isTranscribing { return .gray.opacity(0.5) }
        return speechRecognizer.isRecording ? .red : .white
    }

    private var iconName: String {
        if speechRecognizer.isTranscribing { return "ellipsis" }
        if !awaitingInput { return "mic.slash.fill" }
        return speechRecognizer.isRecording ? "stop.fill" : "mic.fill"
    }

    private var iconColor: Color {
        if !awaitingInput || speechRecognizer.isTranscribing { return .white.opacity(0.5) }
        return speechRecognizer.isRecording ? .white : .black
    }
}
