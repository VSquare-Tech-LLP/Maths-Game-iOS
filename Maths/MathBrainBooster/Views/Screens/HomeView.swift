import SwiftUI

struct HomeView: View {
    @ObservedObject var settings = SettingsViewModel.shared
    @ObservedObject var statsVM = StatsViewModel.shared
    @ObservedObject var achievementMgr = AchievementManager.shared
    @ObservedObject var mistakesMgr = MistakesManager.shared
    @State private var selectedMode: GameMode?
    @State private var showStats = false
    @State private var showAchievements = false
    @State private var showSettings = false
    @State private var showDailyChallenge = false
    @State private var showMistakesWorkout = false
    @State private var showQuickMaths = false
    @State private var showMiniGames = false
    @State private var animateCards = false

    private var theme: ColorTheme { settings.selectedTheme }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        dailyChallengeButton
                        gameModeGrid
                        quickMathsButton
                        miniGamesButton
                        mistakesWorkoutButton
                        quickStatsBar
                    }
                    .padding()
                }

                achievementBanner
            }
            .navigationDestination(item: $selectedMode) { mode in
                DifficultySelectView(gameMode: mode)
            }
            .sheet(isPresented: $showStats) {
                StatsView()
            }
            .sheet(isPresented: $showAchievements) {
                AchievementsView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $showDailyChallenge) {
                DailyChallengeView()
            }
            .fullScreenCover(isPresented: $showMistakesWorkout) {
                MistakesWorkoutView()
            }
            .fullScreenCover(isPresented: $showQuickMaths) {
                QuickMathsSetupView()
            }
            .fullScreenCover(isPresented: $showMiniGames) {
                MiniGamesHubView()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    animateCards = true
                }
                GameCenterManager.shared.authenticate()
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Math Brain")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                    Text("Booster")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [theme.primary, theme.secondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }

                Spacer()

                HStack(spacing: 12) {
                    IconButton(icon: "chart.bar.fill", theme: theme) {
                        showStats = true
                    }
                    IconButton(icon: "trophy.fill", theme: theme) {
                        showAchievements = true
                    }
                    IconButton(icon: "gearshape.fill", theme: theme) {
                        showSettings = true
                    }
                }
            }
        }
        .padding(.top, 8)
    }

    private var gameModeGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(Array(GameMode.allCases.enumerated()), id: \.element.id) { index, mode in
                GameModeCard(mode: mode, theme: theme)
                    .onTapGesture {
                        SoundManager.shared.playButtonTap()
                        HapticManager.shared.buttonTap()
                        selectedMode = mode
                    }
                    .opacity(animateCards ? 1 : 0)
                    .offset(y: animateCards ? 0 : 20)
                    .animation(
                        .easeOut(duration: 0.4).delay(Double(index) * 0.08),
                        value: animateCards
                    )
            }
        }
    }

    private var dailyChallengeButton: some View {
        let challenge = DailyChallengeViewModel.shared
        return Button {
            SoundManager.shared.playButtonTap()
            HapticManager.shared.buttonTap()
            showDailyChallenge = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: Color.red.opacity(0.3), radius: 6, y: 2)

                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Daily Challenge")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(theme.textPrimary)

                        if challenge.isTodayCompleted {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.green)
                        }
                    }

                    if challenge.isTodayCompleted {
                        Text("Completed! Score: \(challenge.todayScore) · \(challenge.currentDayStreak) day streak")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                    } else {
                        Text("3 rounds · Mixed difficulty · New challenge daily")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                    }
                }

                Spacer()

                if !challenge.isTodayCompleted {
                    Text("PLAY")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                colors: [Color.orange, Color.red],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                        .shadow(color: Color.red.opacity(0.3), radius: 4, y: 2)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                }
            }
            .padding(14)
            .background(theme.cardBackground)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.4), Color.red.opacity(0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1
                    )
            )
        }
    }

    private var quickMathsButton: some View {
        Button {
            SoundManager.shared.playButtonTap()
            HapticManager.shared.buttonTap()
            showQuickMaths = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan, Color.blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: Color.blue.opacity(0.3), radius: 6, y: 2)

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Quick Maths")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)

                    Text("Timed challenge · Set your own pace")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()

                Text("GO")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color.cyan, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .shadow(color: Color.blue.opacity(0.3), radius: 4, y: 2)
            }
            .padding(14)
            .background(theme.cardBackground)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.4), Color.blue.opacity(0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1
                    )
            )
        }
    }

    private var miniGamesButton: some View {
        Button {
            SoundManager.shared.playButtonTap()
            HapticManager.shared.buttonTap()
            showMiniGames = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.orange, Color(red: 0.90, green: 0.50, blue: 0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: Color.orange.opacity(0.3), radius: 6, y: 2)

                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Math Games")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)

                    Text("Sudoku, 2048, Memory & more")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()

                Text("PLAY")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(Color(red: 0.45, green: 0.22, blue: 0.0))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 1.0, green: 0.85, blue: 0.30), Color.orange],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .cornerRadius(10)
                    .shadow(color: Color.orange.opacity(0.3), radius: 4, y: 2)
            }
            .padding(14)
            .background(theme.cardBackground)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.4), Color.orange.opacity(0.15)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1
                    )
            )
        }
    }

    private var mistakesWorkoutButton: some View {
        Button {
            SoundManager.shared.playButtonTap()
            HapticManager.shared.buttonTap()
            showMistakesWorkout = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple, Color.pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: Color.pink.opacity(0.3), radius: 6, y: 2)

                    Image(systemName: "pencil.and.outline")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("Mistakes Workout")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(theme.textPrimary)

                        if mistakesMgr.hasMistakes {
                            Text("\(mistakesMgr.uniqueMistakes.count)")
                                .font(.system(size: 12, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .frame(width: 22, height: 22)
                                .background(Color.red)
                                .cornerRadius(11)
                        }
                    }

                    Text("It's ok to make mistakes, just practice again!")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
            }
            .padding(14)
            .background(theme.cardBackground)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.2)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 1
                    )
            )
        }
    }

    private var quickStatsBar: some View {
        HStack(spacing: 0) {
            QuickStat(title: "Games", value: "\(statsVM.totalGamesPlayed)", theme: theme)
            Divider().frame(height: 30).background(theme.textSecondary.opacity(0.3))
            QuickStat(title: "High Score", value: "\(statsVM.allTimeHighScore)", theme: theme)
            Divider().frame(height: 30).background(theme.textSecondary.opacity(0.3))
            QuickStat(title: "Best Streak", value: "\(statsVM.allTimeBestStreak)", theme: theme)
        }
        .padding(.vertical, 14)
        .background(theme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(theme.textSecondary.opacity(0.1), lineWidth: 1)
        )
    }

    private var achievementBanner: some View {
        VStack {
            if achievementMgr.showAchievementBanner,
               let achievement = achievementMgr.newlyUnlocked {
                HStack(spacing: 12) {
                    Image(systemName: achievement.icon)
                        .font(.system(size: 24))
                        .foregroundColor(.yellow)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Achievement Unlocked!")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.yellow)
                        Text(achievement.title)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Spacer()
                }
                .padding()
                .background(Color.black.opacity(0.9))
                .cornerRadius(16)
                .padding(.horizontal)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Spacer()
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: achievementMgr.showAchievementBanner)
    }
}

struct GameModeCard: View {
    let mode: GameMode
    let theme: ColorTheme

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(theme.primary.opacity(0.15))
                    .frame(width: 56, height: 56)

                Image(systemName: mode.symbol)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(theme.primary)
            }

            Text(mode.rawValue)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(theme.textPrimary)

            Text(mode.operatorString)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(theme.cardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(theme.primary.opacity(0.15), lineWidth: 1)
        )
    }
}

struct IconButton: View {
    let icon: String
    let theme: ColorTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(theme.textSecondary)
                .frame(width: 40, height: 40)
                .background(theme.cardBackground)
                .cornerRadius(12)
        }
    }
}

struct QuickStat: View {
    let title: String
    let value: String
    let theme: ColorTheme

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeView()
}
