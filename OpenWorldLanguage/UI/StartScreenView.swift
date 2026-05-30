import SwiftUI

struct StartScreenView: View {
    @ObservedObject var speechRecognizer: SpeechRecognizer
    @ObservedObject var llmEngine: LLMEngine
    let onStart: () -> Void

    // Both models must be ready before the user can start.
    private var allReady: Bool { speechRecognizer.modelReady && llmEngine.modelReady }

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                Spacer()
                titleBlock
                Spacer()
                bottomBlock
            }
        }
    }

    // MARK: - Subviews

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.04, green: 0.06, blue: 0.22),
                Color(red: 0.01, green: 0.01, blue: 0.08)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private var titleBlock: some View {
        VStack(spacing: 10) {
            Text("OpenWorld")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("Language")
                .font(.system(size: 28, weight: .light, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
            Text("Parlez. Vivez. Apprenez.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.4))
                .padding(.top, 14)
        }
    }

    private var bottomBlock: some View {
        VStack(spacing: 18) {
            if allReady {
                Button(action: onStart) {
                    Text("Commencer")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(.blue, in: RoundedRectangle(cornerRadius: 16))
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                VStack(spacing: 14) {
                    loadingDots
                    Text(loadingLabel)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 56)
        .animation(.easeInOut(duration: 0.45), value: allReady)
        .animation(.easeInOut(duration: 0.2), value: loadingLabel)
    }

    // Breathing dot animation as a subtle alternative to a spinner.
    private var loadingDots: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(.white.opacity(0.4))
                    .frame(width: 7, height: 7)
                    .scaleEffect(1.0)
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(i) * 0.18),
                        value: loadingLabel
                    )
            }
        }
    }

    private var loadingLabel: String {
        if speechRecognizer.isWarmingUp {
            return "Préparation du moteur vocal…"
        } else if !speechRecognizer.modelReady {
            return "Chargement du modèle vocal…"
        } else if llmEngine.isLoading {
            return "Chargement du modèle de langue…"
        } else {
            return "Initialisation…"
        }
    }
}
