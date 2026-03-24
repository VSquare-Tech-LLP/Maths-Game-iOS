import SwiftUI

struct StatsView: View {
    @ObservedObject var statsVM = StatsViewModel.shared
    @ObservedObject var settings = SettingsViewModel.shared
    @Environment(\.dismiss) private var dismiss

    private var theme: ColorTheme { settings.selectedTheme }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        overviewSection
                        scoresChart
                        accuracyChart
                        recentGamesSection
                    }
                    .padding()
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(theme.primary)
                }
            }
            .toolbarBackground(theme.background, for: .navigationBar)
            .onAppear { AnalyticsManager.shared.logScreenViewed(screenName: "stats") }
        }
    }

    private var overviewSection: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            OverviewCard(title: "Games Played", value: "\(statsVM.totalGamesPlayed)", icon: "gamecontroller.fill", color: .blue, theme: theme)
            OverviewCard(title: "High Score", value: "\(statsVM.allTimeHighScore)", icon: "trophy.fill", color: .yellow, theme: theme)
            OverviewCard(title: "Avg Accuracy", value: String(format: "%.0f%%", statsVM.overallAccuracy), icon: "target", color: .green, theme: theme)
            OverviewCard(title: "Best Streak", value: "\(statsVM.allTimeBestStreak)", icon: "flame.fill", color: .orange, theme: theme)
        }
    }

    private var scoresChart: some View {
        Group {
            if !statsVM.recentScores.isEmpty {
                BarChartView(
                    data: statsVM.recentScores.map { Double($0) },
                    labels: statsVM.recentScores.indices.map { "\($0 + 1)" },
                    title: "Recent Scores",
                    barColor: theme.primary,
                    theme: theme
                )
            }
        }
    }

    private var accuracyChart: some View {
        Group {
            if !statsVM.recentAccuracies.isEmpty {
                BarChartView(
                    data: statsVM.recentAccuracies,
                    labels: statsVM.recentAccuracies.indices.map { "\($0 + 1)" },
                    title: "Recent Accuracy (%)",
                    barColor: .green,
                    theme: theme
                )
            }
        }
    }

    private var recentGamesSection: some View {
        Group {
            if !statsVM.recentResults.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Games")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.textPrimary)

                    ForEach(statsVM.recentResults) { result in
                        RecentGameRow(result: result, theme: theme)
                    }
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.doc.horizontal")
                        .font(.system(size: 48))
                        .foregroundColor(theme.textSecondary.opacity(0.5))
                    Text("No games played yet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                    Text("Play a game to see your stats here!")
                        .font(.system(size: 14))
                        .foregroundColor(theme.textSecondary.opacity(0.7))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }
}

struct OverviewCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let theme: ColorTheme

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(theme.cardBackground)
        .cornerRadius(14)
    }
}

struct RecentGameRow: View {
    let result: GameResult
    let theme: ColorTheme

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "number.circle.fill")
                .foregroundColor(theme.primary)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(result.mode.rawValue) · \(result.difficulty.rawValue)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                Text(result.date, style: .relative)
                    .font(.system(size: 11))
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(result.score) pts")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                Text(String(format: "%.0f%%", result.accuracy))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(result.accuracy >= 70 ? .green : .orange)
            }
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    StatsView()
}
