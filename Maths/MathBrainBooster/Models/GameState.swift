import Foundation

enum GamePhase {
    case idle
    case countdown
    case playing
    case paused
    case gameOver
}

struct GameStats {
    var correctAnswers: Int = 0
    var wrongAnswers: Int = 0
    var currentStreak: Int = 0
    var bestStreak: Int = 0
    var totalScore: Int = 0
    var multiplier: Int = 1
    var questionsAnswered: Int = 0

    var accuracy: Double {
        guard questionsAnswered > 0 else { return 0 }
        return Double(correctAnswers) / Double(questionsAnswered) * 100
    }
}
