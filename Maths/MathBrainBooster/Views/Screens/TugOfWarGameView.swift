import SwiftUI

struct TugOfWarGameView: View {
    let gameMode: GameMode
    let difficulty: Difficulty

    @StateObject private var vm = TugOfWarViewModel()
    @ObservedObject var settings = SettingsViewModel.shared
    @Environment(\.dismiss) private var dismiss

    private var theme: ColorTheme { settings.selectedTheme }

    private let playerColor = Color.blue
    private let opponentColor = Color.red

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            switch vm.gamePhase {
            case .idle:
                Color.clear.onAppear {
                    vm.startGame(mode: gameMode, difficulty: difficulty)
                }
            case .countdown:
                countdownView
            case .playing, .paused:
                gamePlayView
                    .blur(radius: vm.gamePhase == .paused ? 10 : 0)
                    .overlay { if vm.gamePhase == .paused { pauseOverlay } }
            case .gameOver:
                gameOverView
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            if vm.gamePhase == .playing || vm.gamePhase == .paused {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { vm.resetGame(); dismiss() } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(theme.textSecondary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        vm.gamePhase == .paused ? vm.resumeGame() : vm.pauseGame()
                    } label: {
                        Image(systemName: vm.gamePhase == .paused ? "play.fill" : "pause.fill")
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Countdown

    private var countdownView: some View {
        VStack(spacing: 20) {
            Text("⚔️ Tug of War")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(theme.textSecondary)

            HStack(spacing: 30) {
                VStack(spacing: 4) {
                    Text("You")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(playerColor)
                }
                Text("vs")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                VStack(spacing: 4) {
                    Text(vm.opponentName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(opponentColor)
                }
            }

            Text("\(vm.countdownValue)")
                .font(.system(size: 96, weight: .heavy, design: .rounded))
                .foregroundColor(theme.primary)

            Text("Get Ready!")
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .foregroundColor(theme.textSecondary)
        }
    }

    // MARK: - Main gameplay

    private var gamePlayView: some View {
        VStack(spacing: 0) {
            // Top scoreboard
            scoreboardBar
                .padding(.horizontal)
                .padding(.top, 4)

            // Timer + question counter + pause
            HStack {
                Text("Q\(vm.questionNumber)/\(vm.totalQuestions)")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(theme.textSecondary)
                Spacer()
                TimerRingView(
                    progress: vm.timerProgress,
                    color: vm.timerColor,
                    timeRemaining: vm.timeRemaining,
                    size: 56
                )
                Spacer()
                HStack(spacing: 8) {
                    StreakBadgeView(
                        streak: vm.playerStreak,
                        multiplier: vm.playerMultiplier,
                        theme: theme
                    )
                    Button {
                        vm.pauseGame()
                    } label: {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(theme.cardBackground)
                            .cornerRadius(8)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 6)

            // Tug of war arena
            tugOfWarArena
                .padding(.horizontal)
                .padding(.vertical, 8)

            // Player's question
            if let question = vm.playerQuestion {
                VStack(spacing: 6) {
                    Text(question.text)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.6)
                        .id(question.id)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.8).combined(with: .opacity),
                            removal: .opacity
                        ))

                    Text("= ?")
                        .font(.system(size: 24, weight: .medium, design: .rounded))
                        .foregroundColor(theme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }

            Spacer()

            // Answer options (existing 4-button grid)
            answersSection
                .padding(.horizontal)
                .padding(.bottom, 12)
        }
    }

    // MARK: - Scoreboard

    private var scoreboardBar: some View {
        HStack(spacing: 0) {
            // Player side
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(playerColor)
                        .frame(width: 32, height: 32)
                    Text("🧑")
                        .font(.system(size: 16))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("You")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(playerColor)
                    Text("\(vm.playerScore) pts")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(theme.textSecondary)
                }
            }

            Spacer()

            // Center score
            HStack(spacing: 10) {
                Text("\(vm.playerCorrect)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(playerColor)

                Text(":")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(theme.textSecondary)

                Text("\(vm.opponentCorrect)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(opponentColor)
            }

            Spacer()

            // Opponent side
            HStack(spacing: 8) {
                VStack(alignment: .trailing, spacing: 1) {
                    Text(vm.opponentName)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(opponentColor)
                    Text("\(vm.opponentScore) pts")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(theme.textSecondary)
                }

                ZStack {
                    Circle()
                        .fill(opponentColor)
                        .frame(width: 32, height: 32)
                    Text("🤖")
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(theme.cardBackground)
        .cornerRadius(14)
    }

    // MARK: - Tug of War Arena

    private var tugOfWarArena: some View {
        VStack(spacing: 6) {
            // Win progress indicators
            HStack(spacing: 3) {
                ForEach(0..<vm.maxSteps, id: \.self) { i in
                    let step = -(vm.maxSteps - i)  // negative = player
                    RoundedRectangle(cornerRadius: 3)
                        .fill(step >= vm.tugSteps ? playerColor : playerColor.opacity(0.15))
                        .frame(height: 6)
                }

                RoundedRectangle(cornerRadius: 3)
                    .fill(theme.textSecondary.opacity(0.3))
                    .frame(width: 4, height: 6)

                ForEach(0..<vm.maxSteps, id: \.self) { i in
                    let step = i + 1  // positive = opponent
                    RoundedRectangle(cornerRadius: 3)
                        .fill(step <= vm.tugSteps ? opponentColor : opponentColor.opacity(0.15))
                        .frame(height: 6)
                }
            }
            .frame(height: 8)

            // Tug of war visual
            GeometryReader { geo in
                let midX = geo.size.width / 2
                let offset = vm.ropePosition * (geo.size.width * 0.35)

                ZStack {
                    // Ground line
                    Rectangle()
                        .fill(theme.textSecondary.opacity(0.15))
                        .frame(height: 2)
                        .offset(y: 30)

                    // Center marker
                    Rectangle()
                        .fill(theme.textSecondary.opacity(0.3))
                        .frame(width: 2, height: 24)
                        .offset(y: 18)

                    // Rope
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [Color.brown.opacity(0.8), Color.brown, Color.brown.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 0.55, height: 6)
                        .offset(x: offset, y: 14)

                    // Center flag on rope
                    Image(systemName: "flag.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.yellow)
                        .offset(x: offset, y: 0)

                    // Player characters (left side)
                    HStack(spacing: -4) {
                        playerCharacter(emoji: "🏃", flip: false)
                        playerCharacter(emoji: "🧑‍💼", flip: false)
                    }
                    .offset(x: -midX * 0.48 + offset, y: 6)

                    // Opponent characters (right side)
                    HStack(spacing: -4) {
                        opponentCharacter(emoji: "🧑‍🎓", flip: true)
                        opponentCharacter(emoji: "🏃", flip: true)
                    }
                    .offset(x: midX * 0.48 + offset, y: 6)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: 68)

            // Opponent question bubble
            if let oppQ = vm.opponentQuestion {
                HStack(spacing: 6) {
                    Text(vm.opponentName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(opponentColor)
                    Text("solving:")
                        .font(.system(size: 11))
                        .foregroundColor(theme.textSecondary)
                    Text(oppQ.text + " = ?")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)

                    if vm.opponentShowFeedback {
                        Image(systemName: vm.opponentLastCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(vm.opponentLastCorrect == true ? .green : .red)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(theme.cardBackground.opacity(0.7))
                .cornerRadius(10)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(theme.cardBackground.opacity(0.5))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.textSecondary.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func playerCharacter(emoji: String, flip: Bool) -> some View {
        Text(emoji)
            .font(.system(size: 28))
            .scaleEffect(x: flip ? -1 : 1, y: 1)
    }

    private func opponentCharacter(emoji: String, flip: Bool) -> some View {
        Text(emoji)
            .font(.system(size: 28))
            .scaleEffect(x: flip ? -1 : 1, y: 1)
    }

    // MARK: - Answers

    private var answersSection: some View {
        Group {
            if let question = vm.playerQuestion {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(question.options, id: \.self) { option in
                        AnswerButtonView(
                            answer: option,
                            isTrueFalse: false,
                            isSelected: vm.selectedAnswer == option,
                            isCorrect: option == question.correctAnswer ? true : (vm.selectedAnswer == option ? false : nil),
                            showFeedback: vm.showAnswerFeedback,
                            theme: theme
                        ) {
                            vm.selectAnswer(option)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Game Over

    private var gameOverView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                // Result icon
                VStack(spacing: 12) {
                    if vm.playerWon == true {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 56))
                            .foregroundStyle(
                                LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom)
                            )
                        Text("You Won! 🎉")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(theme.textPrimary)
                    } else if vm.isDraw {
                        Image(systemName: "equal.circle.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.orange)
                        Text("It's a Draw!")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(theme.textPrimary)
                    } else {
                        Image(systemName: "xmark.shield.fill")
                            .font(.system(size: 56))
                            .foregroundColor(.red.opacity(0.8))
                        Text("\(vm.opponentName) Won")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(theme.textPrimary)
                    }
                }

                // Score comparison
                HStack(spacing: 0) {
                    VStack(spacing: 6) {
                        Text("🧑 You")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(playerColor)
                        Text("\(vm.playerScore)")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundColor(playerColor)
                        Text("\(vm.playerCorrect) correct")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(spacing: 8) {
                        Text("vs")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(theme.textSecondary.opacity(0.3))
                            .frame(width: 1, height: 40)
                    }

                    VStack(spacing: 6) {
                        Text("🤖 \(vm.opponentName)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(opponentColor)
                        Text("\(vm.opponentScore)")
                            .font(.system(size: 36, weight: .heavy, design: .rounded))
                            .foregroundColor(opponentColor)
                        Text("\(vm.opponentCorrect) correct")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 18)
                .background(theme.cardBackground)
                .cornerRadius(16)

                // Player stats
                LazyVGrid(columns: [
                    GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())
                ], spacing: 12) {
                    statCard(title: "Accuracy", value: String(format: "%.0f%%", vm.playerStats.accuracy), icon: "target", color: .green)
                    statCard(title: "Best Streak", value: "\(vm.playerBestStreak)", icon: "flame.fill", color: .orange)
                    statCard(title: "Multiplier", value: "×\(vm.playerMultiplier)", icon: "bolt.fill", color: .purple)
                }

                // Buttons
                VStack(spacing: 12) {
                    Button {
                        vm.startGame(mode: gameMode, difficulty: difficulty)
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Rematch")
                        }
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [theme.primary, theme.secondary], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(16)
                    }

                    Button { dismiss() } label: {
                        Text("Back to Home")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                    }
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .background(theme.background)
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
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

    // MARK: - Pause

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
                        vm.startGame(mode: gameMode, difficulty: difficulty)
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
                        vm.resetGame()
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
        TugOfWarGameView(gameMode: .addition, difficulty: .easy)
    }
}
