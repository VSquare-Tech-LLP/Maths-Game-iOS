import Foundation

enum Difficulty: String, CaseIterable, Identifiable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case expert = "Expert"

    var id: String { rawValue }

    var numberRange: ClosedRange<Int> {
        switch self {
        case .easy: return 1...10
        case .medium: return 1...25
        case .hard: return 1...50
        case .expert: return 1...100
        }
    }

    var multiplicationRange: ClosedRange<Int> {
        switch self {
        case .easy: return 1...5
        case .medium: return 1...12
        case .hard: return 2...20
        case .expert: return 5...50
        }
    }

    var timePerQuestion: TimeInterval {
        switch self {
        case .easy: return 15
        case .medium: return 10
        case .hard: return 7
        case .expert: return 5
        }
    }

    var questionsPerRound: Int {
        switch self {
        case .easy: return 10
        case .medium: return 15
        case .hard: return 20
        case .expert: return 25
        }
    }

    var pointsPerCorrect: Int {
        switch self {
        case .easy: return 10
        case .medium: return 20
        case .hard: return 35
        case .expert: return 50
        }
    }

    var icon: String {
        switch self {
        case .easy: return "star"
        case .medium: return "star.leadinghalf.filled"
        case .hard: return "star.fill"
        case .expert: return "bolt.fill"
        }
    }
}
