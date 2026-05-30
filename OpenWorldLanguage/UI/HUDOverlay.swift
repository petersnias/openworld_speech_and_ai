import SwiftUI

struct HUDOverlay: View {
    @ObservedObject var speechRecognizer: SpeechRecognizer
    @ObservedObject var npcSpeaker: NPCSpeaker
    @ObservedObject var dialogueEngine: DialogueEngine

    var body: some View {
        ZStack {
            conversationStack

            if let score = dialogueEngine.sessionScore {
                ScoreCardView(
                    score: score,
                    bestPrevious: SessionStore.shared.bestScore(for: score.scenarioId)
                        .flatMap { $0.id == score.id ? nil : $0 },
                    onPlayAgain: { dialogueEngine.restartScenario() }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        // Spring for hint cards; easeInOut for everything else.
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: dialogueEngine.showHints)
        .animation(.easeInOut(duration: 0.25), value: speechRecognizer.transcript)
        .animation(.easeInOut(duration: 0.4), value: dialogueEngine.sessionScore != nil)
        .animation(.easeInOut(duration: 0.2), value: dialogueEngine.isAwaitingLLMResponse)
    }

    // MARK: - Main conversation stack

    private var conversationStack: some View {
        VStack(spacing: 0) {
            Spacer()

            // NPC speech bubble — asymmetric transition for a more polished feel.
            if !dialogueEngine.currentNPCSpeech.isEmpty {
                npcSpeechBubble
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }

            // Vocabulary hint cards — spring animation applied at parent level.
            if dialogueEngine.showHints {
                hintCardsView
                    .padding(.horizontal, 16)
                    .padding(.bottom, 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // User transcript — colored by word pronunciation quality.
            if !speechRecognizer.transcript.isEmpty {
                TranscriptView(
                    transcript: speechRecognizer.transcript,
                    scoredWords: speechRecognizer.scoredWords
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            // Status labels — only one shown at a time.
            if dialogueEngine.isAwaitingLLMResponse {
                llmThinkingLabel
                    .padding(.bottom, 8)
                    .transition(.opacity)
            } else if speechRecognizer.isTranscribing {
                Text("Transcription en cours…")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.bottom, 8)
                    .transition(.opacity)
            }

            MicButton(
                speechRecognizer: speechRecognizer,
                awaitingInput: dialogueEngine.awaitingUserInput
            )
            .padding(.bottom, 44)
        }
    }

    // MARK: - NPC speech bubble

    private var npcSpeechBubble: some View {
        HStack(alignment: .top, spacing: 10) {
            // Avatar icon — gold tint when LLM-generated to hint the NPC is improvising.
            ZStack(alignment: .bottomTrailing) {
                Image(systemName: "person.fill")
                    .font(.subheadline)
                    .foregroundStyle(.white)
                    .padding(8)
                    .background(
                        dialogueEngine.lastSpeechWasLLMGenerated ? .indigo : .blue,
                        in: Circle()
                    )

                if dialogueEngine.lastSpeechWasLLMGenerated {
                    Image(systemName: "sparkles")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.yellow)
                        .offset(x: 4, y: 4)
                }
            }

            Text(dialogueEngine.currentNPCSpeech)
                .font(.subheadline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.black.opacity(0.65), in: RoundedRectangle(cornerRadius: 14))

            Spacer(minLength: 0)
        }
    }

    // MARK: - LLM thinking label

    private var llmThinkingLabel: some View {
        HStack(spacing: 8) {
            ProgressView()
                .tint(.white)
                .scaleEffect(0.8)
            Text("Le passant réfléchit…")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    // MARK: - Vocabulary hint cards

    private var hintCardsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Vocabulaire utile", systemImage: "lightbulb.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.yellow)
                Spacer()
                Button("Fermer") { dialogueEngine.dismissHints() }
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.65))
            }
            .padding(.horizontal, 14)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(dialogueEngine.activeHints) { hint in
                        VStack(spacing: 4) {
                            Text(hint.french)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Text(hint.english)
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.65))
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
                .padding(.horizontal, 14)
            }
        }
        .padding(.vertical, 12)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 16))
    }
}
