import Foundation

struct GameResult: Identifiable, Codable {
    let id: UUID
    let mode: GameMode
    let difficulty: Difficulty
    let score: Int
    let correctAnswers: Int
    let totalQuestions: Int
    let bestStreak: Int
    let accuracy: Double
    let date: Date

    init(mode: GameMode, difficulty: Difficulty, score: Int, correctAnswers: Int, totalQuestions: Int, bestStreak: Int, accuracy: Double) {
        self.id = UUID()
        self.mode = mode
        self.difficulty = difficulty
        self.score = score
        self.correctAnswers = correctAnswers
        self.totalQuestions = totalQuestions
        self.bestStreak = bestStreak
        self.accuracy = accuracy
        self.date = Date()
    }
}
