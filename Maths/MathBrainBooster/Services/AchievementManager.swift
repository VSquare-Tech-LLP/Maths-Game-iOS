import Foundation
import SwiftUI

final class AchievementManager: ObservableObject {
    static let shared = AchievementManager()

    @Published var achievements: [Achievement] = []
    @Published var newlyUnlocked: Achievement? = nil
    @Published var showAchievementBanner = false
    @Published var modesPlayed: Set<String> = []
    @Published var totalGamesCompleted: Int = 0

    private let achievementsKey = "unlockedAchievements"
    private let modesPlayedKey = "modesPlayed"
    private let gamesCompletedKey = "totalGamesCompleted"

    private init() {
        loadAchievements()
        loadStats()
    }

    private func loadAchievements() {
        let unlockedIDs = UserDefaults.standard.stringArray(forKey: achievementsKey) ?? []
        achievements = Achievement.allAchievements.map { achievement in
            var a = achievement
            a.isUnlocked = unlockedIDs.contains(a.id)
            return a
        }
    }

    private func loadStats() {
        modesPlayed = Set(UserDefaults.standard.stringArray(forKey: modesPlayedKey) ?? [])
        totalGamesCompleted = UserDefaults.standard.integer(forKey: gamesCompletedKey)
    }

    private func saveAchievements() {
        let unlockedIDs = achievements.filter { $0.isUnlocked }.map { $0.id }
        UserDefaults.standard.set(unlockedIDs, forKey: achievementsKey)
    }

    private func saveStats() {
        UserDefaults.standard.set(Array(modesPlayed), forKey: modesPlayedKey)
        UserDefaults.standard.set(totalGamesCompleted, forKey: gamesCompletedKey)
    }

    func unlock(_ achievementID: String) {
        guard let index = achievements.firstIndex(where: { $0.id == achievementID }),
              !achievements[index].isUnlocked else { return }

        achievements[index].isUnlocked = true
        achievements[index].unlockedDate = Date()
        saveAchievements()

        newlyUnlocked = achievements[index]
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showAchievementBanner = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            withAnimation { self?.showAchievementBanner = false }
        }
    }

    func checkAchievements(result: GameResult, stats: GameStats) {
        totalGamesCompleted += 1
        modesPlayed.insert(result.mode.rawValue)
        saveStats()

        unlock("first_game")

        if result.accuracy >= 99.9 {
            unlock("perfect_round")
        }

        if stats.bestStreak >= 10 {
            unlock("streak_10")
        }

        if stats.bestStreak >= 25 {
            unlock("streak_25")
        }

        if result.score >= 1000 {
            unlock("score_1000")
        }

        if modesPlayed.count >= 6 {
            unlock("all_modes")
        }

        if result.difficulty == .expert {
            unlock("expert_complete")
        }

        if totalGamesCompleted >= 50 {
            unlock("games_50")
        }
    }

    func resetAll() {
        UserDefaults.standard.removeObject(forKey: achievementsKey)
        UserDefaults.standard.removeObject(forKey: modesPlayedKey)
        UserDefaults.standard.removeObject(forKey: gamesCompletedKey)
        modesPlayed = []
        totalGamesCompleted = 0
        loadAchievements()
    }
}
