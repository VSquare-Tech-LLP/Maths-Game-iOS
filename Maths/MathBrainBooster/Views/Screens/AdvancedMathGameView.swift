import SwiftUI

struct AdvancedMathGameView: View {
    let mathType: AdvancedMathType
    let difficulty: Difficulty

    @StateObject private var viewModel = AdvancedMathViewModel()
    @ObservedObject var settings = SettingsViewModel.shared
    @Environment(\.dismiss) private var dismiss

    private var theme: ColorTheme { settings.selectedTheme }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            switch viewModel.gamePhase {
            case .idle:
                Color.clear.onAppear {
                    viewModel.startGame(type: mathType, difficulty: difficulty)
                }
            case .countdown:
                countdownView
            case .playing, .paused:
                gamePlayView
            case .gameOver:
                GameOverView(
                    stats: viewModel.stats,
                    mode: .mixed,
                    difficulty: difficulty,
                    onPlayAgain: {
                        viewModel.startGame(type: mathType, difficulty: difficulty)
                    },
                    onHome: {
                        dismiss()
                    }
                )
            }
        }
    }

    // MARK: - Countdown

    private var countdownView: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                Image(systemName: mathType.icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(mathType.gradientColors[0])

                Text(mathType.rawValue)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textSecondary)
            }

            Text("\(viewModel.countdownValue)")
                .font(.system(size: 96, weight: .heavy, design: .rounded))
                .foregroundColor(mathType.gradientColors[0])
                .animation(.easeInOut(duration: 0.3), value: viewModel.countdownValue)

            Text("Get Ready!")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(theme.textSecondary)
        }
    }

    // MARK: - Gameplay

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

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            // Close
            Button {
                viewModel.resetGame()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(theme.cardBackground)
                    .cornerRadius(10)
            }

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

    // MARK: - Question

    private var questionSection: some View {
        VStack(spacing: 12) {
            StreakBadgeView(
                streak: viewModel.stats.currentStreak,
                multiplier: viewModel.stats.multiplier,
                theme: theme
            )

            if let question = viewModel.currentQuestion {
                // Type badge
                Text(mathType.rawValue.uppercased())
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(mathType.gradientColors[0])
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(mathType.gradientColors[0].opacity(0.15))
                    .cornerRadius(6)

                Text(question.text)
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.4)
                    .lineLimit(2)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .id(question.id)

                Text("= ?")
                    .font(.system(size: 28, weight: .medium, design: .rounded))
                    .foregroundColor(theme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }

    // MARK: - Answers

    private var answersSection: some View {
        Group {
            if let question = viewModel.currentQuestion {
                let isDecimal = mathType == .decimals
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(question.options, id: \.self) { option in
                        advancedAnswerButton(
                            option: option,
                            isDecimal: isDecimal,
                            correctAnswer: question.correctAnswer
                        )
                    }
                }
            }
        }
    }

    private func advancedAnswerButton(option: Int, isDecimal: Bool, correctAnswer: Int) -> some View {
        let isSelected = viewModel.selectedAnswer == option
        let isCorrect: Bool? = option == correctAnswer ? true : (isSelected ? false : nil)

        let bgColor: Color = {
            if viewModel.showAnswerFeedback && isSelected {
                return isCorrect == true ? Color.green : Color.red
            }
            if viewModel.showAnswerFeedback && isCorrect == true && !isSelected {
                return Color.green.opacity(0.4)
            }
            return theme.cardBackground
        }()

        let borderCol: Color = {
            if viewModel.showAnswerFeedback && isSelected {
                return isCorrect == true ? Color.green : Color.red
            }
            return mathType.gradientColors[0].opacity(0.3)
        }()

        let displayText: String = isDecimal ? formatDecimal(option) : "\(option)"

        return Button {
            viewModel.selectAnswer(option)
        } label: {
            Text(displayText)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 72)
                .background(bgColor)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(borderCol, lineWidth: 2)
                )
                .scaleEffect(isSelected && viewModel.showAnswerFeedback ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: viewModel.showAnswerFeedback)
        }
        .disabled(viewModel.showAnswerFeedback)
    }

    /// Format tenths integer as decimal string: 15 → "1.5"
    private func formatDecimal(_ tenths: Int) -> String {
        let whole = tenths / 10
        let frac = abs(tenths % 10)
        return "\(whole).\(frac)"
    }

    // MARK: - Pause Overlay

    private var pauseOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()

            VStack(spacing: 24) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(mathType.gradientColors[0])

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
                            LinearGradient(
                                colors: mathType.gradientColors,
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                    }

                    Button {
                        viewModel.startGame(type: mathType, difficulty: difficulty)
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
    AdvancedMathGameView(mathType: .percents, difficulty: .easy)
}
