import SwiftUI

struct NumberMemoryGameView: View {
    @ObservedObject var settings = SettingsViewModel.shared
    @Environment(\.dismiss) private var dismiss
    @State private var phase: NMPhase = .showing
    @State private var level = 1
    @State private var numberToRemember = ""
    @State private var userInput = ""
    @State private var score = 0
    @State private var bestLevel = 0
    @State private var showTime: Double = 2.0
    @State private var isCorrect: Bool?
    @State private var isPaused = false
    @State private var phaseBeforePause: NMPhase?

    private var theme: ColorTheme { settings.selectedTheme }

    enum NMPhase { case showing, input, result, gameOver }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 20) {
                // Top bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(theme.cardBackground).cornerRadius(10)
                    }
                    Spacer()
                    Text("Number Memory")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                    Button { isPaused = true } label: {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(theme.cardBackground).cornerRadius(10)
                    }
                }
                .padding(.horizontal)

                // Level & Score
                HStack(spacing: 24) {
                    VStack(spacing: 2) {
                        Text("Level").font(.system(size: 12, weight: .medium)).foregroundColor(theme.textSecondary)
                        Text("\(level)").font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(theme.primary)
                    }
                    VStack(spacing: 2) {
                        Text("Score").font(.system(size: 12, weight: .medium)).foregroundColor(theme.textSecondary)
                        Text("\(score)").font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(theme.textPrimary)
                    }
                    VStack(spacing: 2) {
                        Text("Best").font(.system(size: 12, weight: .medium)).foregroundColor(theme.textSecondary)
                        Text("\(bestLevel)").font(.system(size: 24, weight: .bold, design: .rounded)).foregroundColor(.orange)
                    }
                }

                // Digits indicator
                HStack(spacing: 4) {
                    Image(systemName: "number")
                        .font(.system(size: 12, weight: .semibold))
                    Text("\(level + 2) digits")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundColor(theme.primary)
                .padding(.horizontal, 12).padding(.vertical, 5)
                .background(theme.primary.opacity(0.12))
                .cornerRadius(8)

                Spacer()

                switch phase {
                case .showing:
                    showingView
                case .input:
                    inputView
                case .result:
                    resultView
                case .gameOver:
                    gameOverView
                }

                Spacer()
            }
            .padding(.top, 8)

            if isPaused {
                MiniGamePauseOverlay(
                    theme: theme,
                    onResume: { isPaused = false },
                    onRestart: { isPaused = false; level = 1; score = 0; startLevel() },
                    onGameSelection: { isPaused = false; dismiss() },
                    onHome: {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(name: .miniGameGoHome, object: nil)
                        }
                    }
                )
            }
        }
        .onAppear { startLevel() }
    }

    private var showingView: some View {
        VStack(spacing: 16) {
            Text("Remember this number")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(theme.textSecondary)

            Text(numberToRemember)
                .font(.system(size: level <= 6 ? 42 : level <= 10 ? 32 : 24, weight: .heavy, design: .monospaced))
                .foregroundColor(theme.primary)
                .padding(.horizontal, 20)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            // Progress bar for show time
            ProgressView(value: 1.0)
                .tint(theme.primary)
                .padding(.horizontal, 60)
        }
    }

    private var inputView: some View {
        VStack(spacing: 20) {
            Text("What was the number?")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(theme.textSecondary)

            Text(userInput.isEmpty ? "_ _ _" : userInput)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(theme.textPrimary)
                .frame(minHeight: 50)

            // Number pad
            VStack(spacing: 8) {
                ForEach(0..<3) { row in
                    HStack(spacing: 8) {
                        ForEach(1...3, id: \.self) { col in
                            let num = row * 3 + col
                            numPadButton("\(num)") { userInput += "\(num)" }
                        }
                    }
                }
                HStack(spacing: 8) {
                    numPadButton("Del") {
                        if !userInput.isEmpty { userInput.removeLast() }
                    }
                    numPadButton("0") { userInput += "0" }
                    Button {
                        checkAnswer()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).frame(height: 50)
                            .background(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var resultView: some View {
        VStack(spacing: 16) {
            Image(systemName: isCorrect == true ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 56))
                .foregroundColor(isCorrect == true ? .green : .red)

            Text(isCorrect == true ? "Correct!" : "Wrong!")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)

            VStack(spacing: 4) {
                Text("Number was: \(numberToRemember)")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(theme.textSecondary)
                Text("You entered: \(userInput)")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(isCorrect == true ? .green : .red)
            }

            Button {
                if isCorrect == true {
                    level += 1
                    startLevel()
                } else {
                    StreakManager.shared.recordActivity()
                    phase = .gameOver
                }
            } label: {
                Text(isCorrect == true ? "Next Level" : "See Results")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity).padding(.vertical, 14)
                    .background(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(14)
            }
            .padding(.horizontal, 40)
        }
    }

    private var gameOverView: some View {
        VStack(spacing: 20) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 56)).foregroundColor(.purple)
            Text("Game Over").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(theme.textPrimary)
            Text("You reached level \(level)").font(.system(size: 16, weight: .medium)).foregroundColor(theme.textSecondary)
            Text("Score: \(score)").font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundColor(.purple)

            VStack(spacing: 12) {
                Button {
                    level = 1; score = 0; startLevel()
                } label: {
                    HStack { Image(systemName: "arrow.counterclockwise"); Text("Play Again") }
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)).cornerRadius(14)
                }
                Button { dismiss() } label: {
                    Text("Back to Games")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.textPrimary).frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(theme.cardBackground).cornerRadius(14)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func numPadButton(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(theme.cardBackground).cornerRadius(12)
        }
    }

    private func startLevel() {
        phase = .showing
        userInput = ""
        isCorrect = nil
        // Generate number with `level + 2` digits
        let digits = level + 2
        var num = ""
        num += "\(Int.random(in: 1...9))"
        for _ in 1..<digits { num += "\(Int.random(in: 0...9))" }
        numberToRemember = num

        showTime = min(Double(digits) * 0.8, 8.0)

        DispatchQueue.main.asyncAfter(deadline: .now() + showTime) { [self] in
            if phase == .showing && !isPaused { phase = .input }
        }
    }

    private func checkAnswer() {
        let correct = userInput == numberToRemember
        isCorrect = correct
        if correct {
            score += level * 10
            bestLevel = max(bestLevel, level)
            SoundManager.shared.playCorrect()
            HapticManager.shared.correctAnswer()
        } else {
            SoundManager.shared.playWrong()
            HapticManager.shared.wrongAnswer()
        }
        phase = .result
    }
}

#Preview { NumberMemoryGameView() }
