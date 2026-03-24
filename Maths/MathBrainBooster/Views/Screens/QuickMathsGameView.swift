import SwiftUI

struct QuickMathsGameView: View {
    let gameMode: GameMode
    let difficulty: Difficulty
    let timerMode: QuickMathsViewModel.TimerMode
    let questionLimit: QuickMathsViewModel.QuestionLimit

    @StateObject private var viewModel = QuickMathsViewModel()
    @ObservedObject var settings = SettingsViewModel.shared
    @Environment(\.dismiss) private var dismiss

    private var theme: ColorTheme { settings.selectedTheme }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            switch viewModel.gamePhase {
            case .idle:
                Color.clear.onAppear {
                    viewModel.startGame(
                        mode: gameMode,
                        difficulty: difficulty,
                        timerMode: timerMode,
                        questionLimit: questionLimit
                    )
                }
            case .countdown:
                countdownView
            case .playing, .paused:
                gamePlayView
            case .gameOver:
                resultsView
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Countdown

    private var countdownView: some View {
        VStack(spacing: 20) {
            Text("Quick Maths")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(theme.textSecondary)

            Text("\(viewModel.countdownValue)")
                .font(.system(size: 96, weight: .heavy, design: .rounded))
                .foregroundColor(theme.primary)
                .animation(.easeInOut(duration: 0.3), value: viewModel.countdownValue)

            VStack(spacing: 6) {
                Text(gameMode.rawValue + " · " + difficulty.rawValue)
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(theme.textSecondary)

                HStack(spacing: 16) {
                    if viewModel.isTimerBased {
                        Label(timerMode.label, systemImage: "clock")
                    }
                    if let max = viewModel.maxQuestions {
                        Label("\(max) Qs", systemImage: "number")
                    }
                    if !viewModel.isTimerBased && !viewModel.hasQuestionLimit {
                        Label("Unlimited", systemImage: "infinity")
                    }
                }
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(theme.textSecondary)
            }

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

    private var topBar: some View {
        HStack {
            // Score
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

            // Timer or unlimited indicator
            if viewModel.isTimerBased {
                quickMathsTimerRing
            } else {
                VStack(spacing: 2) {
                    Image(systemName: "infinity")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(theme.primary)
                    Text("No Limit")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                }
                .frame(width: 72, height: 72)
            }

            Spacer()

            HStack(spacing: 12) {
                // Question counter
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Question")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                    if let max = viewModel.maxQuestions {
                        Text("\(viewModel.questionNumber)/\(max)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(theme.textPrimary)
                    } else {
                        Text("\(viewModel.questionNumber)")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(theme.textPrimary)
                    }
                }

                // Pause button
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

    private var quickMathsTimerRing: some View {
        let size: CGFloat = 80
        let progress = viewModel.timerProgress
        let color = viewModel.timerColor
        let mins = Int(viewModel.timeRemaining) / 60
        let secs = Int(viewModel.timeRemaining) % 60

        return ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 8)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [color.opacity(0.6), color]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * Double(progress))
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.05), value: progress)

            VStack(spacing: 1) {
                Text(String(format: "%d:%02d", mins, secs))
                    .font(.system(size: size * 0.24, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("min")
                    .font(.system(size: size * 0.12, weight: .medium))
                    .opacity(0.7)
            }
            .foregroundColor(color)
        }
        .frame(width: size, height: size)
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

    // MARK: - Pause Overlay

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

                // Quick stats while paused
                HStack(spacing: 20) {
                    pauseStat(title: "Answered", value: "\(viewModel.stats.questionsAnswered)")
                    pauseStat(title: "Correct", value: "\(viewModel.stats.correctAnswers)")
                    pauseStat(title: "Streak", value: "\(viewModel.stats.currentStreak)")
                }

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
                        viewModel.startGame(mode: gameMode, difficulty: difficulty, timerMode: timerMode, questionLimit: questionLimit)
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

    private func pauseStat(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(theme.primary)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(theme.textSecondary)
        }
    }

    // MARK: - Results

    private var resultsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Trophy / Title
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.cyan, Color.blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)

                        Image(systemName: "bolt.fill")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Text("Quick Maths Complete!")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)

                    Text("\(gameMode.rawValue) · \(difficulty.rawValue) · \(timerMode.label)")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.top, 32)

                // Score
                Text("\(viewModel.stats.totalScore)")
                    .font(.system(size: 56, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.cyan, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .contentTransition(.numericText())

                Text("Total Score")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.textSecondary)

                // Stats Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    resultCard(icon: "checkmark.circle.fill", title: "Correct", value: "\(viewModel.stats.correctAnswers)", color: .green)
                    resultCard(icon: "xmark.circle.fill", title: "Wrong", value: "\(viewModel.stats.wrongAnswers)", color: .red)
                    resultCard(icon: "number", title: "Total Questions", value: "\(viewModel.stats.questionsAnswered)", color: .blue)
                    resultCard(icon: "percent", title: "Accuracy", value: String(format: "%.0f%%", viewModel.stats.accuracy), color: .orange)
                    resultCard(icon: "flame.fill", title: "Best Streak", value: "\(viewModel.stats.bestStreak)", color: .red)
                    resultCard(icon: "speedometer", title: "Q/min", value: String(format: "%.1f", viewModel.questionsPerMinute), color: .purple)
                }
                .padding(.horizontal, 4)

                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        viewModel.startGame(mode: gameMode, difficulty: difficulty, timerMode: timerMode, questionLimit: questionLimit)
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Play Again")
                        }
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(
                            LinearGradient(colors: [Color.cyan, Color.blue], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(16)
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
                        .foregroundColor(theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(theme.cardBackground)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(theme.textSecondary.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                .padding(.top, 8)
            }
            .padding()
        }
    }

    private func resultCard(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(theme.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    QuickMathsGameView(
        gameMode: .mixed,
        difficulty: .medium,
        timerMode: .fiveMinutes,
        questionLimit: .unlimited
    )
}
