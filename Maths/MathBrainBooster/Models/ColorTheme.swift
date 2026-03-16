import SwiftUI

struct ColorTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let primary: Color
    let secondary: Color
    let background: Color
    let cardBackground: Color
    let textPrimary: Color
    let textSecondary: Color
    let accent: Color

    static let allThemes: [ColorTheme] = [
        darkMode, ocean, sunset, pinkCandy, forest, midnight
    ]

    static let darkMode = ColorTheme(
        id: "dark",
        name: "Dark Mode",
        primary: Color(red: 0.4, green: 0.6, blue: 1.0),
        secondary: Color(red: 0.6, green: 0.4, blue: 1.0),
        background: Color(red: 0.08, green: 0.08, blue: 0.12),
        cardBackground: Color(red: 0.14, green: 0.14, blue: 0.2),
        textPrimary: .white,
        textSecondary: Color(white: 0.6),
        accent: Color(red: 0.4, green: 0.6, blue: 1.0)
    )

    static let ocean = ColorTheme(
        id: "ocean",
        name: "Ocean Blue",
        primary: Color(red: 0.0, green: 0.7, blue: 0.9),
        secondary: Color(red: 0.0, green: 0.5, blue: 0.8),
        background: Color(red: 0.05, green: 0.1, blue: 0.18),
        cardBackground: Color(red: 0.08, green: 0.15, blue: 0.25),
        textPrimary: .white,
        textSecondary: Color(red: 0.5, green: 0.7, blue: 0.85),
        accent: Color(red: 0.0, green: 0.8, blue: 1.0)
    )

    static let sunset = ColorTheme(
        id: "sunset",
        name: "Sunset",
        primary: Color(red: 1.0, green: 0.5, blue: 0.3),
        secondary: Color(red: 1.0, green: 0.3, blue: 0.4),
        background: Color(red: 0.15, green: 0.08, blue: 0.08),
        cardBackground: Color(red: 0.22, green: 0.12, blue: 0.1),
        textPrimary: .white,
        textSecondary: Color(red: 0.85, green: 0.65, blue: 0.55),
        accent: Color(red: 1.0, green: 0.6, blue: 0.2)
    )

    static let pinkCandy = ColorTheme(
        id: "pinkCandy",
        name: "Pink Candy",
        primary: Color(red: 1.0, green: 0.4, blue: 0.7),
        secondary: Color(red: 0.9, green: 0.3, blue: 0.9),
        background: Color(red: 0.12, green: 0.06, blue: 0.1),
        cardBackground: Color(red: 0.2, green: 0.1, blue: 0.16),
        textPrimary: .white,
        textSecondary: Color(red: 0.85, green: 0.6, blue: 0.75),
        accent: Color(red: 1.0, green: 0.45, blue: 0.7)
    )

    static let forest = ColorTheme(
        id: "forest",
        name: "Forest",
        primary: Color(red: 0.2, green: 0.8, blue: 0.4),
        secondary: Color(red: 0.1, green: 0.6, blue: 0.5),
        background: Color(red: 0.06, green: 0.12, blue: 0.08),
        cardBackground: Color(red: 0.1, green: 0.18, blue: 0.12),
        textPrimary: .white,
        textSecondary: Color(red: 0.55, green: 0.8, blue: 0.6),
        accent: Color(red: 0.3, green: 0.9, blue: 0.5)
    )

    static let midnight = ColorTheme(
        id: "midnight",
        name: "Midnight Purple",
        primary: Color(red: 0.6, green: 0.3, blue: 1.0),
        secondary: Color(red: 0.8, green: 0.2, blue: 0.8),
        background: Color(red: 0.08, green: 0.04, blue: 0.14),
        cardBackground: Color(red: 0.14, green: 0.08, blue: 0.22),
        textPrimary: .white,
        textSecondary: Color(red: 0.7, green: 0.55, blue: 0.85),
        accent: Color(red: 0.7, green: 0.4, blue: 1.0)
    )
}
