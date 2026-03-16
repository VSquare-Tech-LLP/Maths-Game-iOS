import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = SettingsViewModel.shared
    @Environment(\.dismiss) private var dismiss

    private var theme: ColorTheme { settings.selectedTheme }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        themeSection
                        soundHapticsSection
                        gameCenterSection
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
    }

    private var gameCenterSection: some View {
        VStack(spacing: 0) {
            Button {
                if GameCenterManager.shared.isAuthenticated {
                    GameCenterManager.shared.showLeaderboard()
                } else {
                    GameCenterManager.shared.authenticate()
                }
            } label: {
                HStack {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 18))
                        .foregroundColor(theme.primary)
                        .frame(width: 30)

                    Text("Game Center")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.textPrimary)

                    Spacer()

                    Text(GameCenterManager.shared.isAuthenticated ? "Connected" : "Not Connected")
                        .font(.system(size: 13))
                        .foregroundColor(theme.textSecondary)

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
