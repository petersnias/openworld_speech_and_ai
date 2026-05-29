import SwiftUI

struct MicButton: View {
    @ObservedObject var speechRecognizer: SpeechRecognizer

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
        }
        .disabled(!speechRecognizer.modelReady || speechRecognizer.isTranscribing)
        .animation(.easeInOut(duration: 0.2), value: speechRecognizer.isRecording)
    }

    private var buttonColor: Color {
        if speechRecognizer.isTranscribing { return .gray }
        return speechRecognizer.isRecording ? .red : .white
    }

    private var iconName: String {
        if speechRecognizer.isTranscribing { return "ellipsis" }
        return speechRecognizer.isRecording ? "stop.fill" : "mic.fill"
    }

    private var iconColor: Color {
        speechRecognizer.isRecording ? .white : .black
    }
}
