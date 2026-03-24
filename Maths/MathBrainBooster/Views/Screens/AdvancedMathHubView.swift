import SwiftUI

struct AdvancedMathHubView: View {
    @ObservedObject var settings = SettingsViewModel.shared
    @Environment(\.dismiss) private var dismiss

    @State private var selectedType: AdvancedMathType?
    @State private var animateItems = false

    private var theme: ColorTheme { settings.selectedTheme }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection

                        // Game type cards
                        VStack(spacing: 14) {
                            ForEach(Array(AdvancedMathType.allCases.enumerated()), id: \.element.id) { index, type in
                                advancedMathCard(type, index: index)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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
            .navigationDestination(item: $selectedType) { type in
                AdvancedMathDifficultyView(mathType: type)
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    animateItems = true
                }
                AnalyticsManager.shared.logScreenViewed(screenName: "advanced_math_hub")
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 10) {
            Text("Advanced Math")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)

            Text("Train advanced math tasks with integers, powers, fractions and percents")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.top, 8)
    }

    // MARK: - Card

    private func advancedMathCard(_ type: AdvancedMathType, index: Int) -> some View {
        Button {
            SoundManager.shared.playButtonTap()
            HapticManager.shared.buttonTap()
            selectedType = type
        } label: {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: type.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        .shadow(color: type.gradientColors[0].opacity(0.35), radius: 8, y: 3)

                    Image(systemName: type.icon)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(type.rawValue)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)

                    Text(type.subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textSecondary.opacity(0.6))
            }
            .padding(16)
            .background(theme.cardBackground)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [type.gradientColors[0].opacity(0.35), type.gradientColors[1].opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 4, y: 2)
        }
        .opacity(animateItems ? 1 : 0)
        .offset(y: animateItems ? 0 : 20)
        .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.1), value: animateItems)
    }
}

// MARK: - Difficulty Select (same pattern as DifficultySelectView)

struct AdvancedMathDifficultyView: View {
    let mathType: AdvancedMathType
    @ObservedObject var settings = SettingsViewModel.shared
    @State private var selectedDifficulty: Difficulty?
    @State private var navigateToGame = false
    @State private var animateItems = false

    private var theme: ColorTheme { settings.selectedTheme }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: mathType.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                            .shadow(color: mathType.gradientColors[0].opacity(0.4), radius: 10, y: 4)

                        Image(systemName: mathType.icon)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Text(mathType.rawValue)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)

                    Text("Select Difficulty")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.top, 20)

                VStack(spacing: 12) {
                    ForEach(Array(Difficulty.allCases.enumerated()), id: \.element.id) { index, difficulty in
                        Button {
                            SoundManager.shared.playButtonTap()
                            HapticManager.shared.buttonTap()
                            selectedDifficulty = difficulty
                            navigateToGame = true
                        } label: {
                            HStack(spacing: 16) {
                                Image(systemName: difficulty.icon)
                                    .font(.system(size: 22))
                                    .foregroundColor(mathType.gradientColors[0])
                                    .frame(width: 44, height: 44)
                                    .background(mathType.gradientColors[0].opacity(0.15))
                                    .cornerRadius(12)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(difficulty.rawValue)
                                        .font(.system(size: 18, weight: .bold, design: .rounded))
                                        .foregroundColor(theme.textPrimary)

                                    Text("\(difficulty.questionsPerRound) questions · \(Int(difficulty.timePerQuestion))s each · \(difficulty.pointsPerCorrect)pts")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(theme.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(theme.textSecondary)
                            }
                            .padding()
                            .background(theme.cardBackground)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(mathType.gradientColors[0].opacity(0.1), lineWidth: 1)
                            )
                        }
                        .opacity(animateItems ? 1 : 0)
                        .offset(x: animateItems ? 0 : -30)
                        .animation(
                            .easeOut(duration: 0.4).delay(Double(index) * 0.1),
                            value: animateItems
                        )
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
        }
        .navigationDestination(isPresented: $navigateToGame) {
            if let difficulty = selectedDifficulty {
                AdvancedMathGameView(mathType: mathType, difficulty: difficulty)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation {
                animateItems = true
            }
        }
    }
}

#Preview {
    AdvancedMathHubView()
}
