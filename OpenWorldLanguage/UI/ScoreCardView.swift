import SwiftUI

struct ScoreCardView: View {
    let score: SessionScore
    let bestPrevious: SessionScore?
    let onPlayAgain: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 22) {
                starsRow
                statsRow
                if !score.lowConfidenceWords.isEmpty {
                    pronunciationTips
                }
                if let best = bestPrevious, best.stars > score.stars {
                    bestScoreRow(best)
                }
                playAgainButton
            }
            .padding(28)
            .background(.black.opacity(0.88), in: RoundedRectangle(cornerRadius: 24))
            .padding(.horizontal, 28)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black.opacity(0.5))
    }

    // MARK: - Subviews

    private var starsRow: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                ForEach(1...3, id: \.self) { n in
                    Image(systemName: n <= score.stars ? "star.fill" : "star")
                        .font(.system(size: 34))
                        .foregroundStyle(n <= score.stars ? .yellow : .white.opacity(0.25))
                }
            }
            Text(scoreLabel)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 32) {
            statItem(
                value: "\(score.nodeAttempts.values.reduce(0, +))",
                label: "tentatives"
            )
            statItem(
                value: "\(Int(score.avgPronunciationScore * 100))%",
                label: "prononciation"
            )
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 24)
        .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))
        }
    }

    private var pronunciationTips: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("À améliorer", systemImage: "waveform.badge.exclamationmark")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.orange)

            ForEach(score.lowConfidenceWords.prefix(5)) { word in
                HStack {
                    Text(word.word.trimmingCharacters(in: .whitespaces))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color(red: 1.0, green: 0.38, blue: 0.38))
                    Spacer()
                    Text("\(Int(word.probability * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
    }

    private func bestScoreRow(_ best: SessionScore) -> some View {
        HStack(spacing: 6) {
            Text("Votre meilleur :")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
            HStack(spacing: 3) {
                ForEach(1...3, id: \.self) { n in
                    Image(systemName: n <= best.stars ? "star.fill" : "star")
                        .font(.caption)
                        .foregroundStyle(n <= best.stars ? .yellow : .white.opacity(0.2))
                }
            }
        }
    }

    private var playAgainButton: some View {
        Button(action: onPlayAgain) {
            Text("Rejouer")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.blue, in: RoundedRectangle(cornerRadius: 14))
        }
    }

    private var scoreLabel: String {
        switch score.stars {
        case 3: return "Parfait !"
        case 2: return "Bien joué !"
        default: return "Continuez à pratiquer"
        }
    }
}
