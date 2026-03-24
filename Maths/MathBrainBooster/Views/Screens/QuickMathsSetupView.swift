import SwiftUI

struct QuickMathsSetupView: View {
    @ObservedObject var settings = SettingsViewModel.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDifficulty: Difficulty = .medium
    @State private var selectedMode: GameMode = .mixed
    @State private var selectedTimerIndex: Int = 1 // 5 min default
    @State private var customMinutes: Int = 10
    @State private var questionCountIndex: Int = 0 // Unlimited default
    @State private var customQuestionCount: Int = 50
    @State private var showCustomTime = false
    @State private var showCustomQuestions = false
    @State private var showGame = false

    private var theme: ColorTheme { settings.selectedTheme }

    private let timerOptions: [(label: String, minutes: Int?)] = [
        ("1 Min", 1),
        ("5 Min", 5),
        ("15 Min", 15),
        ("20 Min", 20),
        ("Custom", -1),
        ("Unlimited", nil)
    ]

    private let questionOptions: [(label: String, count: Int?)] = [
        ("Unlimited", nil),
        ("10", 10),
        ("25", 25),
        ("50", 50),
        ("100", 100),
        ("Custom", -1)
    ]

    private var timerMode: QuickMathsViewModel.TimerMode {
        let option = timerOptions[selectedTimerIndex]
        if let mins = option.minutes {
            if mins == -1 {
                return .custom(minutes: customMinutes)
            }
            switch mins {
            case 1:  return .oneMinute
            case 5:  return .fiveMinutes
            case 15: return .fifteenMinutes
            case 20: return .twentyMinutes
            default: return .custom(minutes: mins)
            }
        }
        return .unlimited
    }

    private var questionLimit: QuickMathsViewModel.QuestionLimit {
        let option = questionOptions[questionCountIndex]
        if let count = option.count {
            if count == -1 {
                return .fixed(count: customQuestionCount)
            }
            return .fixed(count: count)
        }
        return .unlimited
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        modeSection
                        difficultySection
                        timerSection
                        questionCountSection
                        startButton
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { AnalyticsManager.shared.logScreenViewed(screenName: "quick_maths_setup") }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(theme.textSecondary)
                    }
                }
            }
            .fullScreenCover(isPresented: $showGame) {
                QuickMathsGameView(
                    gameMode: selectedMode,
                    difficulty: selectedDifficulty,
                    timerMode: timerMode,
                    questionLimit: questionLimit
                )
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan, Color.blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)

                Image(systemName: "bolt.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }

            Text("Quick Maths")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)

            Text("Configure your speed challenge")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(theme.textSecondary)
        }
        .padding(.top, 8)
    }

    // MARK: - Mode Selection

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Operation")

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(GameMode.allCases) { mode in
                    Button {
                        SoundManager.shared.playButtonTap()
                        selectedMode = mode
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: mode.symbol)
                                .font(.system(size: 18, weight: .semibold))
                            Text(mode.rawValue)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        .foregroundColor(selectedMode == mode ? .white : theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedMode == mode
                            ? AnyShapeStyle(LinearGradient(colors: [theme.primary, theme.secondary], startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(theme.cardBackground)
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedMode == mode ? Color.clear : theme.textSecondary.opacity(0.15), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Difficulty

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Difficulty")

            HStack(spacing: 8) {
                ForEach(Difficulty.allCases) { diff in
                    Button {
                        SoundManager.shared.playButtonTap()
                        selectedDifficulty = diff
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: diff.icon)
                                .font(.system(size: 16, weight: .semibold))
                            Text(diff.rawValue)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(selectedDifficulty == diff ? .white : theme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedDifficulty == diff
                            ? AnyShapeStyle(LinearGradient(colors: [theme.primary, theme.secondary], startPoint: .leading, endPoint: .trailing))
                            : AnyShapeStyle(theme.cardBackground)
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(selectedDifficulty == diff ? Color.clear : theme.textSecondary.opacity(0.15), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Timer

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Time Limit")

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(Array(timerOptions.enumerated()), id: \.offset) { index, option in
                    Button {
                        SoundManager.shared.playButtonTap()
                        selectedTimerIndex = index
                        if option.minutes == -1 {
                            showCustomTime = true
                        }
                    } label: {
                        Text(option.minutes == -1 && selectedTimerIndex == index ? "\(customMinutes) Min" : option.label)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(selectedTimerIndex == index ? .white : theme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                selectedTimerIndex == index
                                ? AnyShapeStyle(LinearGradient(colors: [Color.cyan, Color.blue], startPoint: .leading, endPoint: .trailing))
                                : AnyShapeStyle(theme.cardBackground)
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(selectedTimerIndex == index ? Color.clear : theme.textSecondary.opacity(0.15), lineWidth: 1)
                            )
                    }
                }
            }

            if showCustomTime && timerOptions[selectedTimerIndex].minutes == -1 {
                customTimePicker
            }
        }
    }

    private var customTimePicker: some View {
        HStack(spacing: 12) {
            Text("Minutes:")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(theme.textSecondary)

            HStack(spacing: 0) {
                Button {
                    if customMinutes > 1 { customMinutes -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(theme.primary)
                }

                Text("\(customMinutes)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                    .frame(width: 60)

                Button {
                    if customMinutes < 60 { customMinutes += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(theme.primary)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(theme.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - Question Count

    private var questionCountSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle("Number of Questions")

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(Array(questionOptions.enumerated()), id: \.offset) { index, option in
                    Button {
                        SoundManager.shared.playButtonTap()
                        questionCountIndex = index
                        if option.count == -1 {
                            showCustomQuestions = true
                        }
                    } label: {
                        Text(option.count == -1 && questionCountIndex == index ? "\(customQuestionCount)" : option.label)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(questionCountIndex == index ? .white : theme.textPrimary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                questionCountIndex == index
                                ? AnyShapeStyle(LinearGradient(colors: [Color.green, Color.mint], startPoint: .leading, endPoint: .trailing))
                                : AnyShapeStyle(theme.cardBackground)
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(questionCountIndex == index ? Color.clear : theme.textSecondary.opacity(0.15), lineWidth: 1)
                            )
                    }
                }
            }

            if showCustomQuestions && questionOptions[questionCountIndex].count == -1 {
                customQuestionPicker
            }
        }
    }

    private var customQuestionPicker: some View {
        HStack(spacing: 12) {
            Text("Questions:")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(theme.textSecondary)

            HStack(spacing: 0) {
                Button {
                    if customQuestionCount > 5 { customQuestionCount -= 5 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(theme.primary)
                }

                Text("\(customQuestionCount)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                    .frame(width: 60)

                Button {
                    if customQuestionCount < 500 { customQuestionCount += 5 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(theme.primary)
                }
            }

            Spacer()
        }
        .padding(12)
        .background(theme.cardBackground)
        .cornerRadius(12)
    }

    // MARK: - Start

    private var startButton: some View {
        Button {
            SoundManager.shared.playButtonTap()
            HapticManager.shared.buttonTap()
            showGame = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "bolt.fill")
                Text("Start Quick Maths")
            }
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [Color.cyan, Color.blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(18)
            .shadow(color: Color.cyan.opacity(0.4), radius: 8, y: 4)
        }
        .padding(.top, 8)
    }

    // MARK: - Helpers

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundColor(theme.textPrimary)
    }
}

#Preview {
    QuickMathsSetupView()
}
