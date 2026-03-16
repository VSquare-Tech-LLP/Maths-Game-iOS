import SwiftUI

struct NumberSequenceGameView: View {
    @ObservedObject var settings = SettingsViewModel.shared
    @Environment(\.dismiss) private var dismiss
    @State private var sequence: [Int] = []
    @State private var hiddenIndex = 0
    @State private var correctAnswer = 0
    @State private var options: [Int] = []
    @State private var selectedAnswer: Int?
    @State private var showFeedback = false
    @State private var score = 0
    @State private var level = 1
    @State private var lives = 3
    @State private var isGameOver = false
    @State private var questionsAnswered = 0
    @State private var correctCount = 0
    @State private var isPaused = false
    @State private var streak = 0

    private var theme: ColorTheme { settings.selectedTheme }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 16) {
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
                    Text("Number Sequence")
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

                // Stats bar
                HStack(spacing: 16) {
                    VStack(spacing: 2) {
                        Text("Level").font(.system(size: 11, weight: .medium)).foregroundColor(theme.textSecondary)
                        Text("\(level)").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(theme.primary)
                    }
                    VStack(spacing: 2) {
                        Text("Score").font(.system(size: 11, weight: .medium)).foregroundColor(theme.textSecondary)
                        Text("\(score)").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(theme.textPrimary)
                    }
                    VStack(spacing: 2) {
                        Text("Streak").font(.system(size: 11, weight: .medium)).foregroundColor(theme.textSecondary)
                        Text("\(streak)").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(.orange)
                    }
                    VStack(spacing: 2) {
                        Text("Lives").font(.system(size: 11, weight: .medium)).foregroundColor(theme.textSecondary)
                        HStack(spacing: 2) {
                            ForEach(0..<3, id: \.self) { i in
                                Image(systemName: i < lives ? "heart.fill" : "heart")
                                    .font(.system(size: 14))
                                    .foregroundColor(i < lives ? .red : theme.textSecondary.opacity(0.3))
                            }
                        }
                    }
                }

                Spacer()

                // Sequence display
                VStack(spacing: 16) {
                    Text("Find the missing number")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(theme.textSecondary)

                    // Sequence cards
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(sequence.enumerated()), id: \.offset) { index, num in
                                if index == hiddenIndex {
                                    Text("?")
                                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                                        .foregroundColor(theme.primary)
                                        .frame(width: 56, height: 56)
                                        .background(theme.primary.opacity(0.15))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(theme.primary, lineWidth: 2)
                                        )
                                } else {
                                    Text("\(num)")
                                        .font(.system(size: 22, weight: .bold, design: .rounded))
                                        .foregroundColor(theme.textPrimary)
                                        .frame(width: 56, height: 56)
                                        .background(theme.cardBackground)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(theme.textSecondary.opacity(0.15), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Pattern hint
                    if level <= 3 {
                        Text("Hint: Look for a pattern between numbers")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.textSecondary.opacity(0.6))
                    }
                }

                Spacer()

                // Answer options
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(options, id: \.self) { option in
                        let isSelected = selectedAnswer == option
                        let isCorrectAnswer = option == correctAnswer
                        Button {
                            selectAnswer(option)
                        } label: {
                            Text("\(option)")
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(
                                    showFeedback && isCorrectAnswer ? .white :
                                    showFeedback && isSelected ? .white :
                                    theme.textPrimary
                                )
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    showFeedback && isCorrectAnswer ? Color.green :
                                    showFeedback && isSelected && !isCorrectAnswer ? Color.red :
                                    theme.cardBackground
                                )
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(
                                            showFeedback && isCorrectAnswer ? Color.green :
                                            showFeedback && isSelected ? Color.red :
                                            theme.primary.opacity(0.2),
                                            lineWidth: 1.5
                                        )
                                )
                        }
                        .disabled(showFeedback || isPaused)
                    }
                }
                .padding(.horizontal)

                Spacer().frame(height: 16)
            }
            .padding(.top, 8)

            if isGameOver { gameOverOverlay }

            if isPaused {
                MiniGamePauseOverlay(
                    theme: theme,
                    onResume: { isPaused = false },
                    onRestart: {
                        isPaused = false
                        lives = 3; score = 0; level = 1; correctCount = 0; streak = 0; isGameOver = false
                        generateQuestion()
                    },
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
        .onAppear { generateQuestion() }
    }

    private func generateQuestion() {
        selectedAnswer = nil
        showFeedback = false

        // Choose pattern type based on level
        let patternType = min(level, 6)
        var seq: [Int] = []
        let len = min(5 + level / 3, 8)

        switch Int.random(in: 1...patternType) {
        case 1: // Arithmetic: a, a+d, a+2d...
            let a = Int.random(in: 1...20)
            let d = Int.random(in: 1...max(1, level * 2))
            for i in 0..<len { seq.append(a + d * i) }
        case 2: // Multiply: a, a*r, a*r^2...
            let a = Int.random(in: 1...5)
            let r = Int.random(in: 2...3)
            var val = a
            for _ in 0..<len { seq.append(val); val *= r }
        case 3: // Squares: 1, 4, 9, 16...
            let start = Int.random(in: 1...5)
            for i in 0..<len { seq.append((start + i) * (start + i)) }
        case 4: // Fibonacci-like
            let a = Int.random(in: 1...5), b = Int.random(in: 1...5)
            seq = [a, b]
            for i in 2..<len { seq.append(seq[i-1] + seq[i-2]) }
        case 5: // Alternating add
            let a = Int.random(in: 1...10)
            let d1 = Int.random(in: 1...5), d2 = Int.random(in: 1...5)
            seq.append(a)
            for i in 1..<len { seq.append(seq[i-1] + (i % 2 == 1 ? d1 : d2)) }
        default: // Triangular numbers
            let start = Int.random(in: 0...3)
            for i in 0..<len { let n = start + i; seq.append(n * (n + 1) / 2) }
        }

        sequence = seq
        hiddenIndex = Int.random(in: 1..<(len - 1)) // Don't hide first or last
        correctAnswer = seq[hiddenIndex]

        // Generate options
        var opts = Set<Int>()
        opts.insert(correctAnswer)
        while opts.count < 4 {
            let offset = Int.random(in: 1...max(5, correctAnswer / 3 + 1)) * (Bool.random() ? 1 : -1)
            let wrong = correctAnswer + offset
            if wrong != correctAnswer && wrong > 0 { opts.insert(wrong) }
        }
        options = Array(opts).shuffled()
    }

    private func selectAnswer(_ answer: Int) {
        guard !showFeedback, !isPaused else { return }
        selectedAnswer = answer
        showFeedback = true
        questionsAnswered += 1

        if answer == correctAnswer {
            streak += 1
            let multiplier = streak >= 5 ? 2 : 1
            score += level * 15 * multiplier
            correctCount += 1
            SoundManager.shared.playCorrect()
            HapticManager.shared.correctAnswer()

            if correctCount % 3 == 0 { level += 1 }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { generateQuestion() }
        } else {
            streak = 0
            lives -= 1
            SoundManager.shared.playWrong()
            HapticManager.shared.wrongAnswer()

            if lives <= 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { isGameOver = true }
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { generateQuestion() }
            }
        }
    }

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "chart.line.uptrend.xyaxis").font(.system(size: 56)).foregroundColor(.cyan)
                Text("Game Over").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(theme.textPrimary)
                HStack(spacing: 20) {
                    VStack { Text("\(score)").font(.system(size: 22, weight: .bold)).foregroundColor(.cyan); Text("Score").font(.system(size: 12)).foregroundColor(theme.textSecondary) }
                    VStack { Text("\(correctCount)").font(.system(size: 22, weight: .bold)).foregroundColor(.green); Text("Correct").font(.system(size: 12)).foregroundColor(theme.textSecondary) }
                    VStack { Text("Lv.\(level)").font(.system(size: 22, weight: .bold)).foregroundColor(.orange); Text("Level").font(.system(size: 12)).foregroundColor(theme.textSecondary) }
                }
                VStack(spacing: 12) {
                    Button { lives = 3; score = 0; level = 1; correctCount = 0; streak = 0; isGameOver = false; generateQuestion() } label: {
                        HStack { Image(systemName: "arrow.counterclockwise"); Text("Play Again") }
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(LinearGradient(colors: [.cyan, .blue], startPoint: .leading, endPoint: .trailing)).cornerRadius(14)
                    }
                    Button { dismiss() } label: {
                        Text("Back to Games").font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(theme.textPrimary).frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(theme.cardBackground).cornerRadius(14)
                    }
                }
            }
            .padding(28)
            .background(RoundedRectangle(cornerRadius: 24).fill(theme.background).shadow(color: .black.opacity(0.3), radius: 20, y: 10))
            .padding(.horizontal, 32)
        }
    }
}

#Preview { NumberSequenceGameView() }
