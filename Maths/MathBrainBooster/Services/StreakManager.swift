import Foundation
import SwiftUI

/// Tracks daily app activity streaks - records each day the user plays any game
@MainActor
final class StreakManager: ObservableObject {
    static let shared = StreakManager()

    // MARK: - Published State

    @Published var currentStreak: Int = 0
    @Published var bestStreak: Int = 0
    @Published var activeDates: Set<String> = []       // "yyyy-MM-dd" strings
    @Published var todayCompleted: Bool = false

    // MARK: - Keys

    private let streakKey = "appStreakCurrent"
    private let bestStreakKey = "appStreakBest"
    private let lastActiveKey = "appStreakLastActive"
    private let activeDatesKey = "appStreakActiveDates"

    // MARK: - Formatter

    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = .current
        return f
    }()

    // MARK: - Init

    private init() {
        loadState()
        refreshStreak()
    }

    // MARK: - Public

    /// Call whenever the user completes any activity (game, daily challenge, mini-game, etc.)
    func recordActivity() {
        let todayStr = formatter.string(from: Date())

        // Already recorded today
        guard !activeDates.contains(todayStr) else { return }

        activeDates.insert(todayStr)
        todayCompleted = true

        let lastActive = UserDefaults.standard.string(forKey: lastActiveKey) ?? ""

        if let lastDate = formatter.date(from: lastActive) {
            let diff = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            if diff == 1 {
                currentStreak += 1
            } else if diff > 1 {
                currentStreak = 1
            }
            // diff == 0 means same day, streak unchanged
        } else {
            currentStreak = 1
        }

        bestStreak = max(bestStreak, currentStreak)

        UserDefaults.standard.set(todayStr, forKey: lastActiveKey)
        saveState()
    }

    /// Get active dates for a specific month (year, month)
    func activeDatesForMonth(year: Int, month: Int) -> Set<Int> {
        let prefix = String(format: "%04d-%02d", year, month)
        var days = Set<Int>()
        for dateStr in activeDates {
            if dateStr.hasPrefix(prefix) {
                let dayStr = String(dateStr.suffix(2))
                if let day = Int(dayStr) {
                    days.insert(day)
                }
            }
        }
        return days
    }

    /// Total active days ever
    var totalActiveDays: Int { activeDates.count }

    /// This week's active day count (Mon-Sun)
    var thisWeekActiveDays: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return 0 }

        var count = 0
        for i in 0..<7 {
            if let day = calendar.date(byAdding: .day, value: i, to: weekStart) {
                let str = formatter.string(from: day)
                if activeDates.contains(str) {
                    count += 1
                }
            }
        }
        return count
    }

    /// Returns an array of booleans for each day of the current week (Mon–Sun)
    func currentWeekStatus() -> [(letter: String, isActive: Bool, isToday: Bool)] {
        let now = Date()
        let todayStr = formatter.string(from: now)

        // Get start of current week (Sunday-based calendar → adjust to show S M T W T F S)
        var cal = Calendar.current
        cal.firstWeekday = 1 // Sunday

        guard let weekInterval = cal.dateInterval(of: .weekOfYear, for: now) else { return [] }
        let weekStart = weekInterval.start

        let dayLetters = ["S", "M", "T", "W", "T", "F", "S"]
        var result: [(letter: String, isActive: Bool, isToday: Bool)] = []

        for i in 0..<7 {
            if let day = cal.date(byAdding: .day, value: i, to: weekStart) {
                let str = formatter.string(from: day)
                result.append((
                    letter: dayLetters[i],
                    isActive: activeDates.contains(str),
                    isToday: str == todayStr
                ))
            }
        }
        return result
    }

    func resetAll() {
        currentStreak = 0
        bestStreak = 0
        activeDates = []
        todayCompleted = false
        UserDefaults.standard.removeObject(forKey: streakKey)
        UserDefaults.standard.removeObject(forKey: bestStreakKey)
        UserDefaults.standard.removeObject(forKey: lastActiveKey)
        UserDefaults.standard.removeObject(forKey: activeDatesKey)
    }

    // MARK: - Private

    /// Refresh streak on app launch – if user missed yesterday, reset streak
    private func refreshStreak() {
        let todayStr = formatter.string(from: Date())
        todayCompleted = activeDates.contains(todayStr)

        let lastActive = UserDefaults.standard.string(forKey: lastActiveKey) ?? ""
        guard !lastActive.isEmpty else { return }

        guard let lastDate = formatter.date(from: lastActive) else { return }
        let diff = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0

        if diff > 1 {
            // Missed at least one day, streak is broken
            currentStreak = 0
            UserDefaults.standard.set(0, forKey: streakKey)
        }
    }

    private func saveState() {
        UserDefaults.standard.set(currentStreak, forKey: streakKey)
        UserDefaults.standard.set(bestStreak, forKey: bestStreakKey)

        // Store active dates as array of strings
        let array = Array(activeDates)
        UserDefaults.standard.set(array, forKey: activeDatesKey)
    }

    private func loadState() {
        currentStreak = UserDefaults.standard.integer(forKey: streakKey)
        bestStreak = UserDefaults.standard.integer(forKey: bestStreakKey)

        if let array = UserDefaults.standard.stringArray(forKey: activeDatesKey) {
            activeDates = Set(array)
        }
    }
}
