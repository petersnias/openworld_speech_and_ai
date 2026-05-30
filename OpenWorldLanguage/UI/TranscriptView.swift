import SwiftUI

struct TranscriptView: View {
    let transcript: String
    let scoredWords: [ScoredWord]

    var body: some View {
        Group {
            if scoredWords.isEmpty {
                Text(transcript)
                    .font(.body)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
            } else {
                Text(attributedTranscript)
                    .font(.body)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 12))
    }

    // Build a single AttributedString with per-word foreground colors.
    // Words are joined by a plain space so the result wraps naturally.
    private var attributedTranscript: AttributedString {
        var result = AttributedString()
        for (index, word) in scoredWords.enumerated() {
            var chunk = AttributedString(word.word)
            chunk.foregroundColor = color(for: word.quality)
            result += chunk
            if index < scoredWords.count - 1 {
                result += AttributedString(" ")
            }
        }
        return result
    }

    private func color(for quality: WordQuality) -> Color {
        switch quality {
        case .good: return .white
        case .fair: return .yellow
        case .poor: return Color(red: 1.0, green: 0.38, blue: 0.38)
        }
    }
}
