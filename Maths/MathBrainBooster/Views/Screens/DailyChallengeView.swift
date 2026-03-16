import SwiftUI

struct DailyChallengeView: View {
    @StateObject private var vm = DailyChallengeViewModel.shared
    @ObservedObject var settings = SettingsViewModel.shared
    @Environment(\.dismiss) private var dismiss

    private var theme: ColorTheme { settings.selectedTheme }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            switch vm.phase {
            case .overview:
                overviewContent
            case .roundIntro:
                roundIntroContent
            case .countdown:
                countdownContent
            case .playing, .paused:
                playingContent
                    .blur(radius: vm.phase == .paused ? 10 : 0)
                    .overlay { if vm.phase == .paused { pauseOverlay } }
            case .roundComplete:
                EmptyView()
            case .results:
                resultsContent
            }
        }
    }

    // MARK: - Overview

    private var overviewContent: some View {
        VStack(spacing: 24) {
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                        .frame(width: 40, height: 40)
                        .background(theme.cardBackground)
                        .cornerRadius(12)
                }
                Spacer()
            }

            VStack(spacing: 8) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Daily Challenge")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)

                Text(formattedDate)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.textSecondary)
            }

            if vm.currentDayStreak > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("\(vm.currentDayStreak) Day Streak")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(20)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Today's Rounds")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.textPrimary)

                ForEach(vm.challenge.rounds) { round in
                    HStack(spacing: 12) {
                        Text("R\(round.roundNumber)")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 36, height: 36)
                            .background(
                                LinearGradient(
                                    colors: roundColors(round.roundNumber),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .cornerRadius(10)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(round.mode.rawValue)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(theme.textPrimary)
                            Text("\(round.difficulty.rawValue) · \(round.questionsCount) questions")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(theme.textSecondary)
                        }

                        Spacer()

                        Image(systemName: round.mode.symbol)
                            .font(.system(size: 16))
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding(12)
                    .background(theme.cardBackground)
                    .cornerRadius(12)
                }
            }

            Spacer()

            if vm.isTodayCompleted {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.green)
                    Text("Today's challenge completed!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                    Text("Score: \(vm.todayScore)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textSecondary)

                    Button {
                        vm.resetChallenge()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Play Again")
                        }
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(14)
                    }
                }
                .padding(.bottom, 16)
            } else {
                Button {
                    vm.startChallenge()
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Challenge")
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.orange, .red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
            }

            Button { dismiss() } label: {
                Text(vm.isTodayCompleted ? "Back to Home" : "Maybe Later")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.textSecondary)
            }
        }
        .padding()
    }

    // MARK: - Round Intro

    private var roundIntroContent: some View {
        VStack(spacing: 24) {
            Spacer()

            if let round = vm.currentRound {
                Text("Round \(round.roundNumber) of \(vm.totalRounds)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.textSecondary)

                Text(round.mode.rawValue)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)

                Image(systemName: round.mode.symbol)
                    .font(.system(size: 48))
                    .foregroundColor(theme.primary)

                VStack(spacing: 6) {
                    Text("\(round.difficulty.rawValue) Difficulty")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                    Text("\(round.questionsCount) questions · \(Int(round.difficulty.timePerQuestion))s each")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textSecondary.opacity(0.7))
                }
            }

            Spacer()

            Button {
                vm.startCurrentRound()
            } label: {
                HStack {
                    Image(systemName: "bolt.fill")
                    Text("Go!")
                }
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: roundColors(vm.currentRoundIndex + 1),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .padding(.bottom, 20)
        }
        .padding()
    }

    // MARK: - Countdown

    private var countdownContent: some View {
        VStack(spacing: 20) {
            if let round = vm.currentRound {
                Text("Round \(round.roundNumber) · \(round.mode.rawValue)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textSecondary)
            }

            Text("\(vm.countdownValue)")
                .font(.system(size: 96, weight: .heavy, design: .rounded))
                .foregroundColor(theme.primary)

            Text("Get Ready!")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(theme.textSecondary)
        }
    }

    // MARK: - Playing

    private var playingContent: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Score")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                    Text("\(vm.currentStats.totalScore)")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                        .contentTransition(.numericText())
                }

                Spacer()

                TimerRingView(
                    progress: vm.timerProgress,
                    color: vm.timerColor,
                    timeRemaining: vm.timeRemaining,
                    size: 72
                )

                Spacer()

                HStack(spacing: 12) {
                    VStack(alignment: .trailing, spacing: 2) {
                        if let round = vm.currentRound {
                            Text("R\(round.roundNumber) · Q\(vm.questionNumber)/\(round.questionsCount)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(theme.textSecondary)
                        }
                        Text("Round \(vm.currentRoundIndex + 1)/\(vm.totalRounds)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(theme.textPrimary)
                    }

                    Button {
                        vm.pauseGame()
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

            StreakBadgeView(
                streak: vm.currentStats.currentStreak,
                multiplier: vm.currentStats.multiplier,
                theme: theme
            )

            if let question = vm.currentQuestion {
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

            Spacer()

            if let question = vm.currentQuestion {
                if question.isTrueFalse {
                    HStack(spacing: 12) {
                        ForEach(question.options, id: \.self) { option in
                            dailyAnswerButton(option: option, question: question)
                        }
                    }
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(question.options, id: \.self) { option in
                            dailyAnswerButton(option: option, question: question)
                        }
                    }
                }
            }

            Spacer().frame(height: 8)
        }
        .padding()
    }

    private func dailyAnswerButton(option: Int, question: Question) -> some View {
        AnswerButtonView(
            answer: option,
            isTrueFalse: question.isTrueFalse,
            isSelected: vm.selectedAnswer == option,
            isCorrect: option == question.correctAnswer ? true : (vm.selectedAnswer == option ? false : nil),
            showFeedback: vm.showAnswerFeedback,
            theme: theme
        ) {
            vm.selectAnswer(option)
        }
    }

    // MARK: - Results

    private var resultsContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(theme.cardBackground)
                            .cornerRadius(10)
                    }
                }

                VStack(spacing: 8) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(colors: [.orange, .yellow], startPoint: .top, endPoint: .bottom)
                        )

                    Text("Challenge Complete!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)

                    Text(formattedDate)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                }

                Text("\(vm.overallScore)")
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                    )

                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    MiniStatCard(title: "Accuracy", value: String(format: "%.0f%%", vm.overallAccuracy), icon: "target", color: .green, theme: theme)
                    MiniStatCard(title: "Best Streak", value: "\(vm.overallBestStreak)", icon: "flame.fill", color: .orange, theme: theme)
                    MiniStatCard(title: "Day Streak", value: "\(vm.currentDayStreak)", icon: "calendar", color: .blue, theme: theme)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Round Breakdown")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.textPrimary)

                    ForEach(Array(vm.roundStats.enumerated()), id: \.offset) { index, stats in
                        if index < vm.challenge.rounds.count {
                            let round = vm.challenge.rounds[index]
                            HStack {
                                Text("R\(round.roundNumber)")
                                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                                    .frame(width: 30, height: 30)
                                    .background(
                                        LinearGradient(
                                            colors: roundColors(round.roundNumber),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .cornerRadius(8)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(round.mode.rawValue)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(theme.textPrimary)
                                    Text("\(stats.correctAnswers)/\(stats.questionsAnswered) correct")
                                        .font(.system(size: 11))
                                        .foregroundColor(theme.textSecondary)
                                }

                                Spacer()

                                Text("\(stats.totalScore) pts")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(theme.primary)
                            }
                            .padding(10)
                            .background(theme.cardBackground)
                            .cornerRadius(10)
                        }
                    }
                }

                Button {
                    vm.resetChallenge()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text("Play Again")
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }

                Button { dismiss() } label: {
                    Text("Back to Home")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                }
            }
            .padding()
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

                VStack(spacing: 12) {
                    Button { vm.resumeGame() } label: {
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
                        vm.resetChallenge()
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

                    Button { dismiss() } label: {
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

    // MARK: - Helpers

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: Date())
    }

    private func roundColors(_ number: Int) -> [Color] {
        switch number {
        case 1: return [.green, .mint]
        case 2: return [.blue, .cyan]
        case 3: return [.orange, .red]
        default: return [.purple, .pink]
        }
    }
}

struct MiniStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let theme: ColorTheme

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(theme.cardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    DailyChallengeView()
}
