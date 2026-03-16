import Foundation

struct MistakeItem: Codable, Identifiable {
    var id: UUID
    let questionText: String
    let correctAnswer: Int
    let userAnswer: Int?
    let mode: GameMode
    let difficulty: Difficulty
    let date: Date
    var practiceCount: Int

    init(questionText: String, correctAnswer: Int, userAnswer: Int?, mode: GameMode, difficulty: Difficulty) {
        self.id = UUID()
        self.questionText = questionText
        self.correctAnswer = correctAnswer
        self.userAnswer = userAnswer
        self.mode = mode
        self.difficulty = difficulty
        self.date = Date()
        self.practiceCount = 0
    }
}
