import SwiftUI

struct TranscriptView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.body)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 12))
    }
}
