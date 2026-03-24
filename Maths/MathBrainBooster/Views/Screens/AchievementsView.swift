import SwiftUI

struct AchievementsView: View {
    @ObservedObject var achievementManager = AchievementManager.shared
    @ObservedObject var settings = SettingsViewModel.shared
    @Environment(\.dismiss) private var dismiss
    @State private var animateItems = false

    private var theme: ColorTheme { settings.selectedTheme }

    var unlockedCount: Int {
        achievementManager.achievements.filter { $0.isUnlocked }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        progressHeader
                        achievementsList
                    }
                    .padding()
                }
            }
            .navigationTitle("Achievements")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(theme.primary)
                }
            }
            .toolbarBackground(theme.background, for: .navigationBar)
            .onAppear {
                withAnimation(.easeOut(duration: 0.5)) {
                    animateItems = true
                }
                AnalyticsManager.shared.logScreenViewed(screenName: "achievements")
            }
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .stroke(theme.primary.opacity(0.2), lineWidth: 10)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: animateItems ? CGFloat(unlockedCount) / CGFloat(achievementManager.achievements.count) : 0)
                    .stroke(theme.primary, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeOut(duration: 1.0), value: animateItems)

                VStack(spacing: 0) {
                    Text("\(unlockedCount)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                    Text("of \(achievementManager.achievements.count)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                }
            }

            Text("Achievements Unlocked")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(theme.textPrimary)
        }
        .padding(.vertical, 8)
    }

    private var achievementsList: some View {
        VStack(spacing: 10) {
            ForEach(Array(achievementManager.achievements.enumerated()), id: \.element.id) { index, achievement in
                AchievementRow(achievement: achievement, theme: theme)
                    .opacity(animateItems ? 1 : 0)
                    .offset(y: animateItems ? 0 : 15)
                    .animation(
                        .easeOut(duration: 0.35).delay(Double(index) * 0.06),
                        value: animateItems
                    )
            }
        }
    }
}

struct AchievementRow: View {
    let achievement: Achievement
    let theme: ColorTheme

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? theme.primary.opacity(0.2) : theme.cardBackground)
                    .frame(width: 50, height: 50)

                Image(systemName: achievement.icon)
                    .font(.system(size: 22))
                    .foregroundColor(achievement.isUnlocked ? theme.primary : theme.textSecondary.opacity(0.3))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(achievement.isUnlocked ? theme.textPrimary : theme.textSecondary.opacity(0.5))

                Text(achievement.description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(theme.textSecondary)
            }

            Spacer()

            if achievement.isUnlocked {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.green)
            } else {
                Image(systemName: "lock.fill")
                    .font(.system(size: 16))
                    .foregroundColor(theme.textSecondary.opacity(0.3))
            }
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    achievement.isUnlocked ? theme.primary.opacity(0.2) : Color.clear,
                    lineWidth: 1
                )
        )
    }
}

#Preview {
    AchievementsView()
}
