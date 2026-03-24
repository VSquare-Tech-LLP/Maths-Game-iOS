import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    static let shared = SettingsViewModel()

    @Published var selectedTheme: ColorTheme {
        didSet { UserDefaults.standard.set(selectedTheme.id, forKey: "selectedTheme") }
    }

    @Published var soundEnabled: Bool {
        didSet {
            SoundManager.shared.isSoundEnabled = soundEnabled
        }
    }

    @Published var hapticsEnabled: Bool {
        didSet {
            HapticManager.shared.isHapticsEnabled = hapticsEnabled
        }
    }

    @Published var showConfirmReset = false

    private init() {
        let themeID = UserDefaults.standard.string(forKey: "selectedTheme") ?? "dark"
        self.selectedTheme = ColorTheme.allThemes.first { $0.id == themeID } ?? .darkMode
        self.soundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        self.hapticsEnabled = UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
    }

    func setTheme(_ theme: ColorTheme) {
        selectedTheme = theme
    }

    func resetAllData() {
        StatsViewModel.shared.resetAll()
        AchievementManager.shared.resetAll()
        StreakManager.shared.resetAll()
        showConfirmReset = false
    }
}
