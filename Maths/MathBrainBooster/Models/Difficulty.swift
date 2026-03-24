import Foundation

enum Difficulty: String, CaseIterable, Identifiable, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
    case expert = "Expert"

    var id: String { rawValue }

    var numberRange: ClosedRange<Int> {
        switch self {
        case .easy:   return 1...10
        case .medium: return 5...30
        case .hard:   return 10...75
        case .expert: return 21...300
        }
    }

    var multiplicationRange: ClosedRange<Int> {
        switch self {
        case .easy:   return 1...5
        case .medium: return 2...12
        case .hard:   return 5...20
        case .expert: return 21...40
        }
    }

    /// Division-specific range so expert division stays solvable
    var divisionRange: ClosedRange<Int> {
        switch self {
        case .easy:   return 1...5
        case .medium: return 2...12
        case .hard:   return 3...18
        case .expert: return 12...30
        }
    }

    var timePerQuestion: TimeInterval {
        switch self {
        case .easy:   return 15
        case .medium: return 10
        case .hard:   return 7
        case .expert: return 5
        }
    }

    var questionsPerRound: Int {
        switch self {
        case .easy:   return 10
        case .medium: return 15
        case .hard:   return 20
        case .expert: return 25
        }
    }

    var pointsPerCorrect: Int {
        switch self {
        case .easy:   return 10
        case .medium: return 20
        case .hard:   return 35
        case .expert: return 50
        }
    }

    var icon: String {
        switch self {
        case .easy:   return "star"
        case .medium: return "star.leadinghalf.filled"
        case .hard:   return "star.fill"
        case .expert: return "bolt.fill"
        }
    }
}
