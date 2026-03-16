import SwiftUI

struct GameView: View {
    let gameMode: GameMode
    let difficulty: Difficulty

    @StateObject private var viewModel = GameViewModel()
    @ObservedObject var settings = SettingsViewModel.shared
    @Environment(\.dismiss) private var dismiss

    private var theme: ColorTheme { settings.selectedTheme }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            switch viewModel.gamePhase {
            case .idle:
                Color.clear.onAppear {
                    viewModel.startGame(mode: gameMode, difficulty: difficulty)
                }
            case .countdown:
                countdownView
            case .playing, .paused:
                gamePlayView
            case .gameOver:
                GameOverView(
                    stats: viewModel.stats,
                    mode: gameMode,
                    difficulty: difficulty,
                    onPlayAgain: {
                        viewModel.startGame(mode: gameMode, difficulty: difficulty)
                    },
                    onHome: {
                        dismiss()
                    }
                )
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if viewModel.gamePhase == .playing || viewModel.gamePhase == .paused {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.resetGame()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(theme.textSecondary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if viewModel.gamePhase == .paused {
                            viewModel.resumeGame()
                        } else {
                            viewModel.pauseGame()
                        }
                    } label: {
                        Image(systemName: viewModel.gamePhase == .paused ? "play.fill" : "pause.fill")
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }
        }
    }

    private var countdownView: some View {
        VStack(spacing: 20) {
            Text(gameMode.rawValue)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(theme.textSecondary)

            Text("\(viewModel.countdownValue)")
                .font(.system(size: 96, weight: .heavy, design: .rounded))
                .foregroundColor(theme.primary)
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 0.3), value: viewModel.countdownValue)

            Text("Get Ready!")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(theme.textSecondary)
        }
    }

    private var gamePlayView: some View {
        VStack(spacing: 16) {
            topBar
            questionSection
            Spacer()
            answersSection
            Spacer().frame(height: 8)
        }
        .padding()
        .blur(radius: viewModel.gamePhase == .paused ? 10 : 0)
        .overlay {
            if viewModel.gamePhase == .paused {
                pauseOverlay
            }
        }
    }

    private var topBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Score")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                Text("\(viewModel.stats.totalScore)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                    .contentTransition(.numericText())
            }

            Spacer()

            TimerRingView(
                progress: viewModel.timerProgress,
                color: viewModel.timerColor,
                timeRemaining: viewModel.timeRemaining,
                size: 72
            )

            Spacer()

            HStack(spacing: 12) {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Question")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                    Text("\(viewModel.questionNumber)/\(viewModel.totalQuestions)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                }

                Button {
                    viewModel.pauseGame()
                } label: {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(theme.cardBackground)
                        .cornerRadius(10)
                }
            }
        }
    }

    private var questionSection: some View {
        VStack(spacing: 12) {
            StreakBadgeView(
                streak: viewModel.stats.currentStreak,
                multiplier: viewModel.stats.multiplier,
                theme: theme
            )

            if let question = viewModel.currentQuestion {
                Text(question.text)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .id(question.id)

                if !question.isTrueFalse {
                    Text("= ?")
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                        .foregroundColor(theme.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    private var answersSection: some View {
        Group {
            if let question = viewModel.currentQuestion {
                if question.isTrueFalse {
                    HStack(spacing: 12) {
                        ForEach(question.options, id: \.self) { option in
                            answerButton(for: option, question: question)
                        }
                    }
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(question.options, id: \.self) { option in
                            answerButton(for: option, question: question)
                        }
                    }
                }
            }
        }
    }

    private func answerButton(for option: Int, question: Question) -> some View {
        AnswerButtonView(
            answer: option,
            isTrueFalse: question.isTrueFalse,
            isSelected: viewModel.selectedAnswer == option,
            isCorrect: option == question.correctAnswer ? true : (viewModel.selectedAnswer == option ? false : nil),
            showFeedback: viewModel.showAnswerFeedback,
            theme: theme
        ) {
            viewModel.selectAnswer(option)
        }
    }

    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(theme.primary)

                Text("Paused")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)

                VStack(spacing: 12) {
                    Button {
                        viewModel.resumeGame()
                    } label: {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Resume")
                        }
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(colors: [theme.primary, theme.secondary], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(14)
                    }

                    Button {
                        viewModel.startGame(mode: gameMode, difficulty: difficulty)
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Restart")
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(theme.cardBackground)
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(theme.textSecondary.opacity(0.2), lineWidth: 1)
                        )
                    }

                    Button {
                        viewModel.resetGame()
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "house.fill")
                            Text("Back to Home")
                        }
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.red.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 8)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(theme.background)
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            )
            .padding(.horizontal, 32)
        }
    }
}

#Preview {
    NavigationStack {
        GameView(gameMode: .addition, difficulty: .easy)
    }
}
