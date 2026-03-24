import SwiftUI
import StoreKit

struct SettingsView: View {
    @ObservedObject var settings = SettingsViewModel.shared
    @ObservedObject var paywallManager = PaywallManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showPaywall = false
    @State private var showRestoreSuccess = false

    private var theme: ColorTheme { settings.selectedTheme }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        proSection
                        themeSection
                        soundHapticsSection
                       // gameCenterSection
                        moreAppsSection
                        dangerZone
                    }
                    .padding()
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(theme.primary)
                }
            }
            .toolbarBackground(theme.background, for: .navigationBar)
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
            .onAppear { AnalyticsManager.shared.logScreenViewed(screenName: "settings") }
            .alert("Restored Successfully!", isPresented: $showRestoreSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your Pro purchase has been restored. Enjoy MathQ Pro!")
            }
            .alert("Reset All Data?", isPresented: $settings.showConfirmReset) {
                Button("Cancel", role: .cancel) {}
                Button("Reset", role: .destructive) {
                    settings.resetAllData()
                }
            } message: {
                Text("This will delete all your stats, achievements, and game history. This cannot be undone.")
            }
        }
    }

    private var proSection: some View {
        VStack(spacing: 0) {
            if paywallManager.isProUser {
                // Pro badge
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.yellow)
                        .frame(width: 30)

                    Text("MathQ Pro")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(theme.textPrimary)

                    Spacer()

                    Text("Active")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.green)
                }
                .padding()
            } else {
                // Upgrade button
                Button {
                    showPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.yellow)
                            .frame(width: 30)

                        Text("Upgrade to Pro")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(theme.textPrimary)

                        Spacer()

                        Text("No Ads")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color(red: 0.3, green: 0.15, blue: 0.0))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.85, blue: 0.0), Color.orange],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(8)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding()
                }

                Divider().background(theme.textSecondary.opacity(0.1))

                // Restore Purchases (only show for non-pro users)
                Button {
                    Task {
                        await paywallManager.restorePurchases()
                        if paywallManager.isProUser {
                            showPaywall = false
                            showRestoreSuccess = true
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 18))
                            .foregroundColor(theme.primary)
                            .frame(width: 30)

                        Text("Restore Purchases")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.textPrimary)

                        Spacer()

                        if paywallManager.isLoading {
                            ProgressView()
                                .tint(theme.textSecondary)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(theme.cardBackground)
        .cornerRadius(14)
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Color Theme")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(theme.textPrimary)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                ForEach(ColorTheme.allThemes) { t in
                    ThemeCard(
                        colorTheme: t,
                        isSelected: settings.selectedTheme.id == t.id,
                        currentTheme: theme
                    ) {
                        SoundManager.shared.playButtonTap()
                        HapticManager.shared.buttonTap()
                        settings.setTheme(t)
                        AnalyticsManager.shared.logSettingsChanged(setting: "theme", value: t.id)
                    }
                }
            }
        }
    }

    private var soundHapticsSection: some View {
        VStack(spacing: 0) {
            SettingsToggleRow(
                title: "Sound Effects",
                icon: "speaker.wave.2.fill",
                isOn: $settings.soundEnabled,
                theme: theme
            )

            Divider().background(theme.textSecondary.opacity(0.1))

            SettingsToggleRow(
                title: "Haptic Feedback",
                icon: "iphone.radiowaves.left.and.right",
                isOn: $settings.hapticsEnabled,
                theme: theme
            )
        }
        .background(theme.cardBackground)
        .cornerRadius(14)
        .onChange(of: settings.soundEnabled) { _, newValue in
            AnalyticsManager.shared.logSettingsChanged(setting: "sound", value: String(newValue))
        }
        .onChange(of: settings.hapticsEnabled) { _, newValue in
            AnalyticsManager.shared.logSettingsChanged(setting: "haptics", value: String(newValue))
        }
    }

//    private var gameCenterSection: some View {
//        VStack(spacing: 0) {
//            Button {
//                if GameCenterManager.shared.isAuthenticated {
//                    GameCenterManager.shared.showLeaderboard()
//                } else {
//                    GameCenterManager.shared.authenticate()
//                }
//            } label: {
//                HStack {
//                    Image(systemName: "gamecontroller.fill")
//                        .font(.system(size: 18))
//                        .foregroundColor(theme.primary)
//                        .frame(width: 30)
//
//                    Text("Game Center")
//                        .font(.system(size: 16, weight: .medium))
//                        .foregroundColor(theme.textPrimary)
//
//                    Spacer()
//
//                    Text(GameCenterManager.shared.isAuthenticated ? "Connected" : "Not Connected")
//                        .font(.system(size: 13))
//                        .foregroundColor(theme.textSecondary)
//
//                    Image(systemName: "chevron.right")
//                        .font(.system(size: 12, weight: .semibold))
//                        .foregroundColor(theme.textSecondary)
//                }
//                .padding()
//            }
//        }
//        .background(theme.cardBackground)
//        .cornerRadius(14)
//    }

    // MARK: - More Apps, Share & Rate

    private var moreAppsSection: some View {
        VStack(spacing: 0) {
            // More Games
            Button {
                if let url = URL(string: "https://apps.apple.com/us/app/no-wifi-games-offline-games/id6468956525") {
                    UIApplication.shared.open(url)
                }
            } label: {
                HStack {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.purple)
                        .frame(width: 30)

                    Text("More Games")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.textPrimary)

                    Spacer()

                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                }
                .padding()
            }

            Divider().background(theme.textSecondary.opacity(0.1))

            // Share App
            ShareLink(
                item: "MathQ - Brain Training Math Game\n\nHey! Check out MathQ - a fun brain training app with math puzzles, Sudoku, 2048, memory games and more. It's perfect for sharpening your mind!\n\nDownload it free:\nhttps://apps.apple.com/app/id6760698492"
            ) {
                HStack {
                    Image(systemName: "square.and.arrow.up.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.blue)
                        .frame(width: 30)

                    Text("Share App")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.textPrimary)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                }
                .padding()
            }

            Divider().background(theme.textSecondary.opacity(0.1))

            // Rate Us — native in-app review popup
            Button {
                if let windowScene = UIApplication.shared.connectedScenes
                    .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                    SKStoreReviewController.requestReview(in: windowScene)
                }
            } label: {
                HStack {
                    Image(systemName: "star.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.yellow)
                        .frame(width: 30)

                    Text("Rate Us")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.textPrimary)

                    Spacer()

                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow.opacity(0.6))
                        }
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                }
                .padding()
            }
        }
        .background(theme.cardBackground)
        .cornerRadius(14)
    }

    private var dangerZone: some View {
        VStack(spacing: 0) {
            Button {
                settings.showConfirmReset = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.red)
                        .frame(width: 30)

                    Text("Reset All Data")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)

                    Spacer()
                }
                .padding()
            }
        }
        .background(theme.cardBackground)
        .cornerRadius(14)
    }
}

struct ThemeCard: View {
    let colorTheme: ColorTheme
    let isSelected: Bool
    let currentTheme: ColorTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    Circle().fill(colorTheme.primary).frame(width: 16, height: 16)
                    Circle().fill(colorTheme.secondary).frame(width: 16, height: 16)
                    Circle().fill(colorTheme.accent).frame(width: 16, height: 16)
                }

                Text(colorTheme.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(currentTheme.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(colorTheme.background)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? currentTheme.primary : Color.clear, lineWidth: 2)
            )
        }
    }
}

struct SettingsToggleRow: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    let theme: ColorTheme

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(theme.primary)
                .frame(width: 30)

            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.textPrimary)

            Spacer()

            Toggle("", isOn: $isOn)
                .tint(theme.primary)
        }
        .padding()
    }
}

#Preview {
    SettingsView()
}
