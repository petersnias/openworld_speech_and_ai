import SwiftUI

struct StartScreenView: View {
    @ObservedObject var speechRecognizer: SpeechRecognizer
    let onStart: () -> Void

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
            if speechRecognizer.modelReady {
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
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.3)
                    Text(loadingLabel)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 56)
        .animation(.easeInOut(duration: 0.45), value: speechRecognizer.modelReady)
        .animation(.easeInOut(duration: 0.2), value: speechRecognizer.isWarmingUp)
    }

    private var loadingLabel: String {
        speechRecognizer.isWarmingUp
            ? "Préparation du moteur vocal…"
            : "Chargement du modèle vocal…"
    }
}
