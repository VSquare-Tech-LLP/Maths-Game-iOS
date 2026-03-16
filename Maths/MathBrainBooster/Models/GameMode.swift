import Foundation

enum GameMode: String, CaseIterable, Identifiable, Codable {
    case addition = "Addition"
    case subtraction = "Subtraction"
    case multiplication = "Multiplication"
    case division = "Division"
    case mixed = "Mixed"
    case trueFalse = "True/False"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .addition: return "plus"
        case .subtraction: return "minus"
        case .multiplication: return "multiply"
        case .division: return "divide"
        case .mixed: return "shuffle"
        case .trueFalse: return "checkmark.circle"
        }
    }

    var operatorString: String {
        switch self {
        case .addition: return "+"
        case .subtraction: return "-"
        case .multiplication: return "×"
        case .division: return "÷"
        case .mixed: return "?"
        case .trueFalse: return "T/F"
        }
    }

    var color: String {
        switch self {
        case .addition: return "modeGreen"
        case .subtraction: return "modeBlue"
        case .multiplication: return "modeOrange"
        case .division: return "modePurple"
        case .mixed: return "modePink"
        case .trueFalse: return "modeTeal"
        }
    }
}
