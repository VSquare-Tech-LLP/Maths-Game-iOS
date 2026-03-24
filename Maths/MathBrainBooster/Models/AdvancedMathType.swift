import SwiftUI

enum AdvancedMathType: String, CaseIterable, Identifiable, Codable, Hashable {
    case integers = "Integers"
    case squares = "Squares & Powers"
    case decimals = "Decimal Fractions"
    case percents = "Percents"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .integers:  return "Tasks with positive & negative numbers"
        case .squares:   return "Squares, cubes & powers"
        case .decimals:  return "Solve tasks with decimal fractions"
        case .percents:  return "Find the percent of a number"
        }
    }

    var icon: String {
        switch self {
        case .integers:  return "plusminus"
        case .squares:   return "x.squareroot"
        case .decimals:  return "textformat.123"
        case .percents:  return "percent"
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .integers:  return [Color(red: 0.40, green: 0.45, blue: 0.95), Color(red: 0.28, green: 0.30, blue: 0.80)]
        case .squares:   return [Color(red: 0.65, green: 0.35, blue: 0.90), Color(red: 0.48, green: 0.22, blue: 0.78)]
        case .decimals:  return [Color(red: 0.20, green: 0.75, blue: 0.55), Color(red: 0.12, green: 0.58, blue: 0.42)]
        case .percents:  return [Color(red: 0.95, green: 0.55, blue: 0.20), Color(red: 0.85, green: 0.38, blue: 0.12)]
        }
    }
}
