import Foundation
import SwiftUI

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

    var gradientColors: [Color] {
        switch self {
        case .addition: return [Color(red: 0.2, green: 0.85, blue: 0.5), Color(red: 0.1, green: 0.65, blue: 0.4)]
        case .subtraction: return [Color(red: 0.35, green: 0.6, blue: 1.0), Color(red: 0.25, green: 0.4, blue: 0.9)]
        case .multiplication: return [Color(red: 1.0, green: 0.6, blue: 0.2), Color(red: 0.95, green: 0.4, blue: 0.15)]
        case .division: return [Color(red: 0.7, green: 0.4, blue: 1.0), Color(red: 0.55, green: 0.25, blue: 0.9)]
        case .mixed: return [Color(red: 1.0, green: 0.4, blue: 0.6), Color(red: 0.9, green: 0.25, blue: 0.5)]
        case .trueFalse: return [Color(red: 0.0, green: 0.75, blue: 0.85), Color(red: 0.0, green: 0.55, blue: 0.8)]
        }
    }
}
