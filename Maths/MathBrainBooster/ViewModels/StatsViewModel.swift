import Foundation
import SwiftUI

@MainActor
final class StatsViewModel: ObservableObject {
    static let shared = StatsViewModel()

    @Published var gameResults: [GameResult] = []
    @Published var allTimeHighScore: Int = 0
    @Published var allTimeBestStreak: Int = 0
    @Published var totalGamesPlayed: Int = 0

    private let resultsKey = "gameResults"
    private let highScoreKey = "allTimeHighScore"
    private let bestStreakKey = "allTimeBestStreak"

    private init() {
        loadResults()
    }

    var recentResults: [GameResult] {
        Array(gameResults.suffix(10).reversed())
    }

    var overallAccuracy: Double {
        guard !gameResults.isEmpty else { return 0 }
        let total = gameResults.reduce(0.0) { $0 + $1.accuracy }
        return total / Double(gameResults.count)
    }

    var averageScore: Int {
        guard !gameResults.isEmpty else { return 0 }
        let total = gameResults.reduce(0) { $0 + $1.score }
        return total / gameResults.count
    }

    var recentScores: [Int] {
        Array(gameResults.suffix(10).map { $0.score })
    }

    var recentAccuracies: [Double] {
        Array(gameResults.suffix(10).map { $0.accuracy })
    }

    func addResult(_ result: GameResult) {
        gameResults.append(result)
        totalGamesPlayed = gameResults.count

        if result.score > allTimeHighScore {
            allTimeHighScore = result.score
            UserDefaults.standard.set(allTimeHighScore, forKey: highScoreKey)
        }

        if result.bestStreak > allTimeBestStreak {
            allTimeBestStreak = result.bestStreak
            UserDefaults.standard.set(allTimeBestStreak, forKey: bestStreakKey)
        }

        // Record activity for streak tracking
        StreakManager.shared.recordActivity()

        saveResults()
    }

    func results(for mode: GameMode) -> [GameResult] {
        gameResults.filter { $0.mode == mode }
    }

    func results(for difficulty: Difficulty) -> [GameResult] {
        gameResults.filter { $0.difficulty == difficulty }
    }

    private func saveResults() {
        if let data = try? JSONEncoder().encode(gameResults) {
            UserDefaults.standard.set(data, forKey: resultsKey)
        }
    }

    private func loadResults() {
        if let data = UserDefaults.standard.data(forKey: resultsKey),
           let results = try? JSONDecoder().decode([GameResult].self, from: data) {
            self.gameResults = results
        }
        allTimeHighScore = UserDefaults.standard.integer(forKey: highScoreKey)
        allTimeBestStreak = UserDefaults.standard.integer(forKey: bestStreakKey)
        totalGamesPlayed = gameResults.count
    }

    func resetAll() {
        gameResults = []
        allTimeHighScore = 0
        allTimeBestStreak = 0
        totalGamesPlayed = 0
        UserDefaults.standard.removeObject(forKey: resultsKey)
        UserDefaults.standard.removeObject(forKey: highScoreKey)
        UserDefaults.standard.removeObject(forKey: bestStreakKey)
    }
}
