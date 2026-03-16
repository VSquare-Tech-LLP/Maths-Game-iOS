import Foundation

struct DailyChallenge: Codable {
    let date: String
    let seed: Int
    let rounds: [DailyChallengeRound]
    var isCompleted: Bool
    var totalScore: Int
    var accuracy: Double
    var bestStreak: Int

    static func forToday() -> DailyChallenge {
        let dateStr = Self.todayString()
        let seed = Self.seedForDate(dateStr)
        let rounds = Self.generateRounds(seed: seed)
        return DailyChallenge(
            date: dateStr,
            seed: seed,
            rounds: rounds,
            isCompleted: false,
            totalScore: 0,
            accuracy: 0,
            bestStreak: 0
        )
    }

    static func todayString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    static func seedForDate(_ dateStr: String) -> Int {
        dateStr.utf8.reduce(0) { $0 &+ Int($1) &* 31 }
    }

    static func generateRounds(seed: Int) -> [DailyChallengeRound] {
        let modes: [GameMode] = [.addition, .subtraction, .multiplication, .division, .mixed]
        let difficulties: [Difficulty] = [.easy, .medium, .hard]

        var rng = seed
        func nextRandom() -> Int {
            rng = (rng &* 1103515245 &+ 12345) & 0x7fffffff
            return rng
        }

        return (0..<3).map { i in
            let modeIndex = abs(nextRandom()) % modes.count
            let diffIndex = min(i, difficulties.count - 1)
            return DailyChallengeRound(
                roundNumber: i + 1,
                mode: modes[modeIndex],
                difficulty: difficulties[diffIndex],
                questionsCount: 8
            )
        }
    }
}

struct DailyChallengeRound: Codable, Identifiable {
    var id: Int { roundNumber }
    let roundNumber: Int
    let mode: GameMode
    let difficulty: Difficulty
    let questionsCount: Int
}
