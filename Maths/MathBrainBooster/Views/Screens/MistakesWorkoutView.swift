import SwiftUI

struct MistakesWorkoutView: View {
    @ObservedObject var mistakesManager = MistakesManager.shared
    @ObservedObject var settings = SettingsViewModel.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isWorkoutActive = false
    @State private var currentIndex = 0
    @State private var workoutMistakes: [MistakeItem] = []
    @State private var userInput = ""
    @State private var showFeedback = false
    @State private var isCorrect = false
    @State private var correctThisSession = 0
    @State private var wrongThisSession = 0
    @State private var showResults = false
    @State private var masteredQuestions: [MistakeItem] = []
    @State private var showClearConfirm = false

    private var theme: ColorTheme { settings.selectedTheme }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            if showResults {
                resultsView
            } else if isWorkoutActive {
                workoutPlayView
            } else {
                mistakesListView
            }
        }
    }

    // MARK: - Mistakes List

    private var mistakesListView: some View {
        VStack(spacing: 0) {
            // Header
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
                if mistakesManager.hasMistakes {
                    Button { showClearConfirm = true } label: {
                        Text("Clear All")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)

            // Title section
            VStack(spacing: 8) {
                Image(systemName: "pencil.and.outline")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.purple, Color.pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("Mistakes Workout")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)

                Text("It's ok to make mistakes, just practice again!")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)

                if mistakesManager.hasMistakes {
                    Text("\(mistakesManager.uniqueMistakes.count) questions to practice")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.purple)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.12))
                        .cornerRadius(10)
                }
            }
            .padding(.vertical, 16)

            if mistakesManager.hasMistakes {
                // Mistakes list grouped by mode
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(GameMode.allCases.filter { mode in
                            mistakesManager.mistakesByMode[mode] != nil
                        }) { mode in
                            if let items = mistakesManager.mistakesByMode[mode] {
                                modeSection(mode: mode, items: items)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }

                // Start workout button pinned at bottom
                Button {
                    startWorkout()
                } label: {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Practice")
                    }
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            } else {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.green)
                    Text("No mistakes yet!")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                    Text("Play some games and any wrong answers\nwill appear here for practice")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                Spacer()
            }
        }
        .alert("Clear All Mistakes?", isPresented: $showClearConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                mistakesManager.clearAll()
            }
        } message: {
            Text("This will remove all \(mistakesManager.mistakeCount) mistakes from your practice list.")
        }
    }

    private func modeSection(mode: GameMode, items: [MistakeItem]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: mode.symbol)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.primary)
                Text(mode.rawValue)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                Text("(\(items.count))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.textSecondary)
            }

            // Show unique items only
            let uniqueItems = uniqueItems(from: items)
            ForEach(uniqueItems) { item in
                HStack(spacing: 12) {
                    // Question
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(item.questionText) = ?")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(theme.textPrimary)

                        if let userAns = item.userAnswer {
                            Text("Your answer: \(userAns)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.red.opacity(0.8))
                        } else {
                            Text("Timed out")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.orange)
                        }
                    }

                    Spacer()

                    if item.practiceCount > 0 {
                        Text("×\(item.practiceCount + 1)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .cornerRadius(6)
                    }

                    // Delete button
                    Button {
                        withAnimation {
                            mistakesManager.removeMistake(item)
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(theme.textSecondary.opacity(0.5))
                    }
                }
                .padding(12)
                .background(theme.cardBackground)
                .cornerRadius(12)
            }
        }
    }

    private func uniqueItems(from items: [MistakeItem]) -> [MistakeItem] {
        var seen = Set<String>()
        return items.filter { item in
            let key = "\(item.questionText)_\(item.correctAnswer)"
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }

    // MARK: - Workout Play

    private var workoutPlayView: some View {
        VStack(spacing: 20) {
            // Top bar
            HStack {
                Button {
                    isWorkoutActive = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(theme.cardBackground)
                        .cornerRadius(10)
                }

                Spacer()

                Text("\(currentIndex + 1) / \(workoutMistakes.count)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)

                Spacer()

                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.green)
                        Text("\(correctThisSession)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                    }

                    HStack(spacing: 3) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.red)
                        Text("\(wrongThisSession)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(theme.cardBackground)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(
                            width: geo.size.width * CGFloat(currentIndex + 1) / CGFloat(max(workoutMistakes.count, 1)),
                            height: 8
                        )
                        .animation(.easeInOut(duration: 0.3), value: currentIndex)
                }
            }
            .frame(height: 8)
            .padding(.horizontal)

            if currentIndex < workoutMistakes.count {
                let mistake = workoutMistakes[currentIndex]

                Spacer()

                // Mode badge
                HStack(spacing: 6) {
                    Image(systemName: mistake.mode.symbol)
                        .font(.system(size: 12))
                    Text(mistake.mode.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(theme.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(theme.primary.opacity(0.12))
                .cornerRadius(10)

                // Question
                Text(mistake.questionText)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                    .minimumScaleFactor(0.5)

                Text("= ?")
                    .font(.system(size: 30, weight: .medium, design: .rounded))
                    .foregroundColor(theme.textSecondary)

                // Feedback
                if showFeedback {
                    VStack(spacing: 8) {
                        Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(isCorrect ? .green : .red)

                        if isCorrect {
                            Text("Correct! 🎉")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                        } else {
                            VStack(spacing: 4) {
                                Text("Not quite!")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.red)
                                Text("The answer is \(mistake.correctAnswer)")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .foregroundColor(theme.primary)
                            }
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
                }

                Spacer()

                // Number input
                if !showFeedback {
                    numberInputSection(correctAnswer: mistake.correctAnswer)
                } else {
                    Button {
                        moveToNext()
                    } label: {
                        HStack {
                            Text(currentIndex + 1 < workoutMistakes.count ? "Next Question" : "See Results")
                            Image(systemName: "arrow.right")
                        }
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                }
            }
        }
    }

    private func numberInputSection(correctAnswer: Int) -> some View {
        VStack(spacing: 10) {
            // Input display
            HStack {
                Spacer()
                Text(userInput.isEmpty ? "—" : userInput)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(userInput.isEmpty ? theme.textSecondary.opacity(0.4) : theme.textPrimary)
                    .frame(height: 50)
                Spacer()
            }
            .padding(.horizontal, 20)
            .background(theme.cardBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(theme.primary.opacity(0.3), lineWidth: 2)
            )
            .padding(.horizontal)

            // Number pad
            VStack(spacing: 8) {
                ForEach(0..<3) { row in
                    HStack(spacing: 8) {
                        ForEach(1...3, id: \.self) { col in
                            let num = row * 3 + col
                            numberButton("\(num)") {
                                userInput += "\(num)"
                            }
                        }
                    }
                }
                HStack(spacing: 8) {
                    // Clear
                    Button {
                        if !userInput.isEmpty {
                            userInput = String(userInput.dropLast())
                        }
                    } label: {
                        Image(systemName: "delete.left.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(14)
                    }

                    // Zero
                    numberButton("0") {
                        userInput += "0"
                    }

                    // Submit
                    Button {
                        submitAnswer(correctAnswer: correctAnswer)
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(userInput.isEmpty ? Color.blue.opacity(0.4) : Color.blue)
                            .cornerRadius(14)
                    }
                    .disabled(userInput.isEmpty)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 12)
        }
    }

    private func numberButton(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            SoundManager.shared.playButtonTap()
            action()
        }) {
            Text(text)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(theme.cardBackground)
                .cornerRadius(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(theme.textSecondary.opacity(0.15), lineWidth: 1)
                )
        }
    }

    // MARK: - Results

    private var resultsView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "star.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(
                    LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
                )

            Text("Workout Complete!")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)

            // Score
            HStack(spacing: 40) {
                VStack(spacing: 4) {
                    Text("\(correctThisSession)")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundColor(.green)
                    Text("Correct")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                }

                VStack(spacing: 4) {
                    Text("\(wrongThisSession)")
                        .font(.system(size: 40, weight: .heavy, design: .rounded))
                        .foregroundColor(.red)
                    Text("Wrong")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                }
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(theme.cardBackground)
            .cornerRadius(16)
            .padding(.horizontal)

            if !masteredQuestions.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.green)
                    Text("\(masteredQuestions.count) question\(masteredQuestions.count == 1 ? "" : "s") mastered!")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.green)
                    Text("Removed from practice list")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(14)
                .padding(.horizontal)
            }

            Spacer()

            VStack(spacing: 12) {
                if mistakesManager.hasMistakes {
                    Button {
                        startWorkout()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Practice Again")
                        }
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(colors: [.purple, .pink], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(16)
                    }
                }

                Button { dismiss() } label: {
                    Text("Back to Home")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Actions

    private func startWorkout() {
        workoutMistakes = mistakesManager.uniqueMistakes.shuffled()
        currentIndex = 0
        correctThisSession = 0
        wrongThisSession = 0
        masteredQuestions = []
        userInput = ""
        showFeedback = false
        showResults = false
        isWorkoutActive = true
    }

    private func submitAnswer(correctAnswer: Int) {
        guard let answer = Int(userInput) else { return }
        let correct = answer == correctAnswer
        isCorrect = correct

        if correct {
            correctThisSession += 1
            SoundManager.shared.playCorrect()
            HapticManager.shared.correctAnswer()

            // Remove from mistakes if answered correctly
            let mistake = workoutMistakes[currentIndex]
            masteredQuestions.append(mistake)
            mistakesManager.removeMistakeByQuestion(
                questionText: mistake.questionText,
                correctAnswer: mistake.correctAnswer
            )
        } else {
            wrongThisSession += 1
            SoundManager.shared.playWrong()
            HapticManager.shared.wrongAnswer()
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            showFeedback = true
        }
    }

    private func moveToNext() {
        if currentIndex + 1 < workoutMistakes.count {
            currentIndex += 1
            userInput = ""
            showFeedback = false
            isCorrect = false
        } else {
            showResults = true
            isWorkoutActive = false
            // Record activity for streak tracking
            StreakManager.shared.recordActivity()
            // Show interstitial ad after workout
            InterstitialAdManager.shared.gameCompleted()
        }
    }
}

#Preview {
    MistakesWorkoutView()
}
