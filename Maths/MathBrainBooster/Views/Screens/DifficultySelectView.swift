import SwiftUI

struct DifficultySelectView: View {
    let gameMode: GameMode
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
                    Image(systemName: gameMode.symbol)
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(theme.primary)

                    Text(gameMode.rawValue)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)

                    Text("Select Difficulty")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.top, 20)

                VStack(spacing: 12) {
                    ForEach(Array(Difficulty.allCases.enumerated()), id: \.element.id) { index, difficulty in
                        DifficultyCard(difficulty: difficulty, theme: theme) {
                            SoundManager.shared.playButtonTap()
                            HapticManager.shared.buttonTap()
                            selectedDifficulty = difficulty
                            navigateToGame = true
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
                if gameMode == .addition {
                    TugOfWarGameView(gameMode: gameMode, difficulty: difficulty)
                } else {
                    GameView(gameMode: gameMode, difficulty: difficulty)
                }
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

struct DifficultyCard: View {
    let difficulty: Difficulty
    let theme: ColorTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: difficulty.icon)
                    .font(.system(size: 22))
                    .foregroundColor(theme.primary)
                    .frame(width: 44, height: 44)
                    .background(theme.primary.opacity(0.15))
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
                    .stroke(theme.primary.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

#Preview {
    NavigationStack {
        DifficultySelectView(gameMode: .addition)
    }
}
