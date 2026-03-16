import SwiftUI

struct GameOverView: View {
    let stats: GameStats
    let mode: GameMode
    let difficulty: Difficulty
    let onPlayAgain: () -> Void
    let onHome: () -> Void

    @ObservedObject var settings = SettingsViewModel.shared
    @State private var animateResults = false
    @State private var showScore = false

    private var theme: ColorTheme { settings.selectedTheme }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                headerSection
                scoreSection
                statsGrid
                buttonsSection
            }
            .padding()
        }
        .background(theme.background)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
                animateResults = true
            }
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.4)) {
                showScore = true
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: resultIcon)
                .font(.system(size: 60))
                .foregroundColor(resultColor)
                .symbolEffect(.bounce, value: animateResults)

            Text(resultTitle)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)

            Text("\(mode.rawValue) · \(difficulty.rawValue)")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.textSecondary)
        }
        .padding(.top, 20)
    }

    private var scoreSection: some View {
        VStack(spacing: 8) {
            Text("\(stats.totalScore)")
                .font(.system(size: 56, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [theme.primary, theme.secondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .scaleEffect(showScore ? 1 : 0.3)
                .opacity(showScore ? 1 : 0)

            Text("Total Score")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.textSecondary)
        }
    }

    private var statsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            StatCard(title: "Correct", value: "\(stats.correctAnswers)/\(stats.questionsAnswered)", icon: "checkmark.circle.fill", color: .green, theme: theme)
                .opacity(animateResults ? 1 : 0)

            StatCard(title: "Accuracy", value: String(format: "%.0f%%", stats.accuracy), icon: "target", color: .blue, theme: theme)
                .opacity(animateResults ? 1 : 0)

            StatCard(title: "Best Streak", value: "\(stats.bestStreak)", icon: "flame.fill", color: .orange, theme: theme)
                .opacity(animateResults ? 1 : 0)

            StatCard(title: "Max Multiplier", value: "×\(stats.bestStreak >= 10 ? 3 : (stats.bestStreak >= 5 ? 2 : 1))", icon: "bolt.fill", color: .purple, theme: theme)
                .opacity(animateResults ? 1 : 0)
        }
    }

    private var buttonsSection: some View {
        VStack(spacing: 12) {
            Button(action: {
                SoundManager.shared.playButtonTap()
                HapticManager.shared.buttonTap()
                onPlayAgain()
            }) {
                HStack {
                    Image(systemName: "arrow.counterclockwise")
                    Text("Play Again")
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [theme.primary, theme.secondary],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }

            Button(action: {
                SoundManager.shared.playButtonTap()
                onHome()
            }) {
                HStack {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(theme.cardBackground)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(theme.primary.opacity(0.2), lineWidth: 1)
                )
            }

            if GameCenterManager.shared.isAuthenticated {
                Button {
                    GameCenterManager.shared.showLeaderboard(mode: mode, difficulty: difficulty)
                } label: {
                    HStack {
                        Image(systemName: "gamecontroller.fill")
                        Text("Leaderboard")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                }
                .padding(.top, 4)
            }
        }
    }

    private var resultIcon: String {
        if stats.accuracy >= 90 { return "crown.fill" }
        if stats.accuracy >= 70 { return "star.fill" }
        if stats.accuracy >= 50 { return "hand.thumbsup.fill" }
        return "arrow.up.circle.fill"
    }

    private var resultColor: Color {
        if stats.accuracy >= 90 { return .yellow }
        if stats.accuracy >= 70 { return .green }
        if stats.accuracy >= 50 { return .blue }
        return .orange
    }

    private var resultTitle: String {
        if stats.accuracy >= 90 { return "Excellent!" }
        if stats.accuracy >= 70 { return "Great Job!" }
        if stats.accuracy >= 50 { return "Good Try!" }
        return "Keep Practicing!"
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let theme: ColorTheme

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)

            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(theme.cardBackground)
        .cornerRadius(14)
    }
}

#Preview {
    GameOverView(
        stats: {
            var s = GameStats()
            s.correctAnswers = 8
            s.wrongAnswers = 2
            s.questionsAnswered = 10
            s.totalScore = 420
            s.bestStreak = 6
            return s
        }(),
        mode: .addition,
        difficulty: .medium,
        onPlayAgain: {},
        onHome: {}
    )
}
