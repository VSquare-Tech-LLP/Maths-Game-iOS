import Foundation
import SwiftUI

@MainActor
final class MistakesManager: ObservableObject {
    static let shared = MistakesManager()

    @Published var mistakes: [MistakeItem] = []

    private let storageKey = "mistakesList"

    private init() {
        loadMistakes()
    }

    var mistakeCount: Int { mistakes.count }

    var hasMistakes: Bool { !mistakes.isEmpty }

    // Group mistakes by mode
    var mistakesByMode: [GameMode: [MistakeItem]] {
        Dictionary(grouping: mistakes, by: { $0.mode })
    }

    // Get unique question texts (avoid duplicates of same question)
    var uniqueMistakes: [MistakeItem] {
        var seen = Set<String>()
        return mistakes.filter { item in
            let key = "\(item.questionText)_\(item.correctAnswer)"
            if seen.contains(key) { return false }
            seen.insert(key)
            return true
        }
    }

    func addMistake(questionText: String, correctAnswer: Int, userAnswer: Int?, mode: GameMode, difficulty: Difficulty) {
        // Check if this exact question already exists
        let key = "\(questionText)_\(correctAnswer)"
        if let index = mistakes.firstIndex(where: { "\($0.questionText)_\($0.correctAnswer)" == key }) {
            // Update existing - increment practice count as it was wrong again
            mistakes[index].practiceCount += 1
        } else {
            let item = MistakeItem(
                questionText: questionText,
                correctAnswer: correctAnswer,
                userAnswer: userAnswer,
                mode: mode,
                difficulty: difficulty
            )
            mistakes.append(item)
        }
        saveMistakes()
    }

    func removeMistake(_ item: MistakeItem) {
        mistakes.removeAll { $0.id == item.id }
        saveMistakes()
    }

    func removeMistakeByQuestion(questionText: String, correctAnswer: Int) {
        mistakes.removeAll {
            $0.questionText == questionText && $0.correctAnswer == correctAnswer
        }
        saveMistakes()
    }

    func clearAll() {
        mistakes = []
        saveMistakes()
    }

    func clearMistakes(for mode: GameMode) {
        mistakes.removeAll { $0.mode == mode }
        saveMistakes()
    }

    private func saveMistakes() {
        if let data = try? JSONEncoder().encode(mistakes) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadMistakes() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let loaded = try? JSONDecoder().decode([MistakeItem].self, from: data) {
            self.mistakes = loaded
        }
    }
}
