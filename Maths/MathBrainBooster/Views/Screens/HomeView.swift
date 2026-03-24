import SwiftUI

struct HomeView: View {
    @ObservedObject var settings = SettingsViewModel.shared
    @ObservedObject var statsVM = StatsViewModel.shared
    @ObservedObject var achievementMgr = AchievementManager.shared
    @ObservedObject var mistakesMgr = MistakesManager.shared
    @ObservedObject var paywallManager = PaywallManager.shared
    @ObservedObject var streakMgr = StreakManager.shared
    @State private var selectedMode: GameMode?
    @State private var showStats = false
    @State private var showAchievements = false
    @State private var showSettings = false
    @State private var showDailyChallenge = false
    @State private var showMistakesWorkout = false
    @State private var showQuickMaths = false
    @State private var showMiniGames = false
    @State private var showAdvancedMath = false
    @State private var showPaywall = false
    @State private var showStreakHistory = false
    @State private var animateCards = false

    private var theme: ColorTheme { settings.selectedTheme }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        StreakCardView(theme: theme) {
                            showStreakHistory = true
                        }
                        dailyChallengeButton
                        gameModeGrid
                        quickMathsButton
                        miniGamesButton
                        advancedMathButton
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
                    .transition(.move(edge: .bottom))
            }
            .fullScreenCover(isPresented: $showMistakesWorkout) {
                MistakesWorkoutView()
                    .transition(.move(edge: .bottom))
            }
            .fullScreenCover(isPresented: $showQuickMaths) {
                QuickMathsSetupView()
                    .transition(.move(edge: .bottom))
            }
            .fullScreenCover(isPresented: $showMiniGames) {
                MiniGamesHubView()
                    .transition(.move(edge: .bottom))
            }
            .fullScreenCover(isPresented: $showAdvancedMath) {
                AdvancedMathHubView()
                    .transition(.move(edge: .bottom))
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
            .fullScreenCover(isPresented: $showStreakHistory) {
                StreakHistoryView()
            }
            .onAppear {
                withAnimation(.easeOut(duration: 0.6)) {
                    animateCards = true
                }
                GameCenterManager.shared.authenticate()
                AnalyticsManager.shared.logScreenViewed(screenName: "home")
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MathQ")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                }

                Spacer()

                HStack(spacing: 12) {
                    if !paywallManager.isProUser {
                        Button {
                            SoundManager.shared.playButtonTap()
                            HapticManager.shared.buttonTap()
                            showPaywall = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 14, weight: .bold))
                                Text("PRO")
                                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                            }
                            .foregroundColor(Color(red: 0.3, green: 0.15, blue: 0.0))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.85, blue: 0.0), Color.orange],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(10)
                            .shadow(color: Color.orange.opacity(0.3), radius: 4, y: 2)
                        }
                    }
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
            GridItem(.flexible(), spacing: 14),
            GridItem(.flexible(), spacing: 14)
        ], spacing: 14) {
            ForEach(Array(GameMode.allCases.enumerated()), id: \.element.id) { index, mode in
                GameModeCard(mode: mode, theme: theme)
                    .onTapGesture {
                        SoundManager.shared.playButtonTap()
                        HapticManager.shared.buttonTap()
                        InterstitialAdManager.shared.buttonClicked {
                            selectedMode = mode
                        }
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
            InterstitialAdManager.shared.buttonClicked {
                showDailyChallenge = true
            }
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
            InterstitialAdManager.shared.buttonClicked {
                showQuickMaths = true
            }
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
            InterstitialAdManager.shared.buttonClicked {
                showMiniGames = true
            }
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

    private var advancedMathButton: some View {
        Button {
            SoundManager.shared.playButtonTap()
            HapticManager.shared.buttonTap()
            InterstitialAdManager.shared.buttonClicked {
                showAdvancedMath = true
            }
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.30, green: 0.80, blue: 0.45), Color(red: 0.18, green: 0.62, blue: 0.32)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: Color.green.opacity(0.3), radius: 6, y: 2)

                    Image(systemName: "x.squareroot")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Advanced Math")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)

                    Text("Integers, powers, fractions & percents")
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
                            colors: [Color(red: 0.30, green: 0.80, blue: 0.45), Color(red: 0.18, green: 0.62, blue: 0.32)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .shadow(color: Color.green.opacity(0.3), radius: 4, y: 2)
            }
            .padding(14)
            .background(theme.cardBackground)
            .cornerRadius(18)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(
                        LinearGradient(
                            colors: [Color.green.opacity(0.4), Color.green.opacity(0.15)],
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
            InterstitialAdManager.shared.buttonClicked {
                showMistakesWorkout = true
            }
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
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: mode.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: mode.gradientColors[0].opacity(0.4), radius: 8, y: 4)

                Image(systemName: mode.symbol)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 4) {
                Text(mode.rawValue)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)

                Text(mode.operatorString)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(mode.gradientColors[0].opacity(0.8))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(
            ZStack {
                theme.cardBackground
                LinearGradient(
                    colors: [mode.gradientColors[0].opacity(0.08), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        )
        .cornerRadius(22)
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    LinearGradient(
                        colors: [mode.gradientColors[0].opacity(0.3), mode.gradientColors[1].opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.15), radius: 6, y: 3)
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
