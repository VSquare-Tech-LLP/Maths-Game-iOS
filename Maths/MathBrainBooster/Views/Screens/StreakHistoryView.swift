import SwiftUI

struct StreakHistoryView: View {
    @ObservedObject var settings = SettingsViewModel.shared
    @ObservedObject var streakMgr = StreakManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @State private var displayedMonth: Date = Date()

    private var theme: ColorTheme { settings.selectedTheme }
    private var isIPad: Bool { hSizeClass == .regular }

    private let calendar = Calendar.current
    private let dayLetters = ["S", "M", "T", "W", "T", "F", "S"]

    private var streakColor: Color {
        Color(red: 1.0, green: 0.65, blue: 0.0)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                theme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: isIPad ? 28 : 24) {
                        streakStatsCards
                        calendarSection
                        monthSummary
                    }
                    .padding(.horizontal, isIPad ? 32 : 16)
                    .padding(.vertical, isIPad ? 24 : 16)
                    .padding(.bottom, 20)
                    .frame(maxWidth: isIPad ? 700 : .infinity)
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Streak History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: isIPad ? 18 : 16, weight: .semibold, design: .rounded))
                        .foregroundColor(streakColor)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Stats Cards

    private var streakStatsCards: some View {
        HStack(spacing: isIPad ? 16 : 12) {
            StreakStatCard(
                icon: "flame.fill",
                iconColors: [Color(red: 1.0, green: 0.8, blue: 0.0), streakColor],
                title: "Current",
                value: "\(streakMgr.currentStreak)",
                subtitle: "day\(streakMgr.currentStreak == 1 ? "" : "s")",
                theme: theme,
                isIPad: isIPad
            )

            StreakStatCard(
                icon: "trophy.fill",
                iconColors: [Color(red: 1.0, green: 0.85, blue: 0.0), Color(red: 1.0, green: 0.6, blue: 0.0)],
                title: "Best",
                value: "\(streakMgr.bestStreak)",
                subtitle: "day\(streakMgr.bestStreak == 1 ? "" : "s")",
                theme: theme,
                isIPad: isIPad
            )

            StreakStatCard(
                icon: "calendar.badge.checkmark",
                iconColors: [Color(red: 0.3, green: 0.85, blue: 0.5), Color(red: 0.15, green: 0.7, blue: 0.4)],
                title: "Total",
                value: "\(streakMgr.totalActiveDays)",
                subtitle: "day\(streakMgr.totalActiveDays == 1 ? "" : "s")",
                theme: theme,
                isIPad: isIPad
            )
        }
    }

    // MARK: - Calendar

    private var calendarSection: some View {
        VStack(spacing: isIPad ? 20 : 16) {
            // Month navigation
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: isIPad ? 18 : 16, weight: .bold))
                        .foregroundColor(theme.textSecondary)
                        .frame(width: isIPad ? 44 : 36, height: isIPad ? 44 : 36)
                        .background(theme.cardBackground)
                        .cornerRadius(isIPad ? 12 : 10)
                }

                Spacer()

                Text(monthYearString(displayedMonth))
                    .font(.system(size: isIPad ? 24 : 20, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        let next = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                        // Don't go past current month
                        if next <= Date() || calendar.isDate(next, equalTo: Date(), toGranularity: .month) {
                            displayedMonth = next
                        }
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: isIPad ? 18 : 16, weight: .bold))
                        .foregroundColor(canGoForward ? theme.textSecondary : theme.textSecondary.opacity(0.3))
                        .frame(width: isIPad ? 44 : 36, height: isIPad ? 44 : 36)
                        .background(theme.cardBackground)
                        .cornerRadius(isIPad ? 12 : 10)
                }
                .disabled(!canGoForward)
            }
            .padding(.horizontal, isIPad ? 8 : 4)

            // Day headers
            HStack(spacing: 0) {
                ForEach(0..<7, id: \.self) { i in
                    Text(dayLetters[i])
                        .font(.system(size: isIPad ? 16 : 13, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar grid
            let gridData = calendarGrid()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: isIPad ? 8 : 4), count: 7), spacing: isIPad ? 12 : 8) {
                ForEach(0..<gridData.count, id: \.self) { i in
                    let cell = gridData[i]
                    calendarCell(cell)
                }
            }
        }
        .padding(isIPad ? 24 : 18)
        .background(theme.cardBackground)
        .cornerRadius(isIPad ? 22 : 18)
        .overlay(
            RoundedRectangle(cornerRadius: isIPad ? 22 : 18)
                .stroke(theme.textSecondary.opacity(0.1), lineWidth: 1)
        )
    }

    @ViewBuilder
    private func calendarCell(_ cell: CalendarCell) -> some View {
        let circleSize: CGFloat = isIPad ? 46 : 34
        let fontSize: CGFloat = isIPad ? 18 : 14
        let cellHeight: CGFloat = isIPad ? 50 : 36

        if cell.day == 0 {
            // Empty cell
            Text("")
                .frame(height: cellHeight)
        } else {
            VStack(spacing: 2) {
                ZStack {
                    if cell.isActive {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 1.0, green: 0.8, blue: 0.0), streakColor],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: circleSize, height: circleSize)

                        Text("\(cell.day)")
                            .font(.system(size: fontSize, weight: .heavy, design: .rounded))
                            .foregroundColor(.black)
                    } else if cell.isToday {
                        Circle()
                            .stroke(streakColor.opacity(0.5), lineWidth: isIPad ? 2.5 : 2)
                            .frame(width: circleSize, height: circleSize)

                        Text("\(cell.day)")
                            .font(.system(size: fontSize, weight: .bold, design: .rounded))
                            .foregroundColor(theme.textPrimary)
                    } else if cell.isFuture {
                        Text("\(cell.day)")
                            .font(.system(size: fontSize, weight: .medium, design: .rounded))
                            .foregroundColor(theme.textSecondary.opacity(0.3))
                    } else {
                        Text("\(cell.day)")
                            .font(.system(size: fontSize, weight: .medium, design: .rounded))
                            .foregroundColor(theme.textSecondary)
                    }
                }
                .frame(height: cellHeight)
            }
        }
    }

    // MARK: - Month Summary

    private var monthSummary: some View {
        let (year, month) = yearMonth(displayedMonth)
        let activeDays = streakMgr.activeDatesForMonth(year: year, month: month)
        let totalDaysInMonth = daysInMonth()
        let passedDays = passedDaysInMonth()
        let rate: Double = passedDays > 0 ? Double(activeDays.count) / Double(passedDays) * 100 : 0

        return VStack(spacing: isIPad ? 18 : 14) {
            HStack {
                Text("Monthly Summary")
                    .font(.system(size: isIPad ? 20 : 17, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                Spacer()
            }

            HStack(spacing: isIPad ? 20 : 16) {
                MonthlyStat(
                    label: "Active Days",
                    value: "\(activeDays.count)/\(totalDaysInMonth)",
                    theme: theme,
                    isIPad: isIPad
                )

                MonthlyStat(
                    label: "Completion",
                    value: "\(Int(rate))%",
                    theme: theme,
                    isIPad: isIPad
                )

                MonthlyStat(
                    label: "This Week",
                    value: "\(streakMgr.thisWeekActiveDays)/7",
                    theme: theme,
                    isIPad: isIPad
                )
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: isIPad ? 8 : 6)
                        .fill(theme.textSecondary.opacity(0.15))

                    RoundedRectangle(cornerRadius: isIPad ? 8 : 6)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 1.0, green: 0.8, blue: 0.0), streakColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * (totalDaysInMonth > 0 ? CGFloat(activeDays.count) / CGFloat(totalDaysInMonth) : 0)))
                }
            }
            .frame(height: isIPad ? 10 : 8)
        }
        .padding(isIPad ? 24 : 18)
        .background(theme.cardBackground)
        .cornerRadius(isIPad ? 22 : 18)
        .overlay(
            RoundedRectangle(cornerRadius: isIPad ? 22 : 18)
                .stroke(theme.textSecondary.opacity(0.1), lineWidth: 1)
        )
    }

    // MARK: - Helpers

    private var canGoForward: Bool {
        let next = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
        return next <= Date() || calendar.isDate(next, equalTo: Date(), toGranularity: .month)
    }

    private func monthYearString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f.string(from: date)
    }

    private func yearMonth(_ date: Date) -> (Int, Int) {
        let c = calendar.dateComponents([.year, .month], from: date)
        return (c.year ?? 2024, c.month ?? 1)
    }

    private func daysInMonth() -> Int {
        let (year, month) = yearMonth(displayedMonth)
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        guard let date = calendar.date(from: comps) else { return 30 }
        return calendar.range(of: .day, in: .month, for: date)?.count ?? 30
    }

    private func passedDaysInMonth() -> Int {
        let (year, month) = yearMonth(displayedMonth)
        let (curYear, curMonth) = yearMonth(Date())

        if year < curYear || (year == curYear && month < curMonth) {
            return daysInMonth() // Entire month has passed
        } else if year == curYear && month == curMonth {
            return calendar.component(.day, from: Date())
        }
        return 0
    }

    private func calendarGrid() -> [CalendarCell] {
        let (year, month) = yearMonth(displayedMonth)
        let activeDays = streakMgr.activeDatesForMonth(year: year, month: month)

        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = 1

        guard let firstDay = calendar.date(from: comps) else { return [] }
        let weekdayOfFirst = calendar.component(.weekday, from: firstDay) // 1=Sun
        let totalDays = calendar.range(of: .day, in: .month, for: firstDay)?.count ?? 30

        let todayComps = calendar.dateComponents([.year, .month, .day], from: Date())
        let todayDay = (todayComps.year == year && todayComps.month == month) ? (todayComps.day ?? 0) : 0

        let isCurrentOrPast = (year < (todayComps.year ?? 0)) ||
            (year == (todayComps.year ?? 0) && month <= (todayComps.month ?? 0))

        var cells: [CalendarCell] = []

        // Empty cells before first day
        for _ in 0..<(weekdayOfFirst - 1) {
            cells.append(CalendarCell(day: 0, isActive: false, isToday: false, isFuture: false))
        }

        for d in 1...totalDays {
            let isActive = activeDays.contains(d)
            let isToday = d == todayDay
            let isFuture: Bool
            if !isCurrentOrPast {
                isFuture = true
            } else if year == (todayComps.year ?? 0) && month == (todayComps.month ?? 0) {
                isFuture = d > todayDay
            } else {
                isFuture = false
            }
            cells.append(CalendarCell(day: d, isActive: isActive, isToday: isToday, isFuture: isFuture))
        }

        return cells
    }
}

// MARK: - Models

private struct CalendarCell {
    let day: Int
    let isActive: Bool
    let isToday: Bool
    let isFuture: Bool
}

// MARK: - Subviews

private struct StreakStatCard: View {
    let icon: String
    let iconColors: [Color]
    let title: String
    let value: String
    let subtitle: String
    let theme: ColorTheme
    var isIPad: Bool = false

    var body: some View {
        VStack(spacing: isIPad ? 10 : 8) {
            Image(systemName: icon)
                .font(.system(size: isIPad ? 28 : 22, weight: .bold))
                .foregroundStyle(
                    LinearGradient(colors: iconColors, startPoint: .top, endPoint: .bottom)
                )

            Text(value)
                .font(.system(size: isIPad ? 36 : 28, weight: .heavy, design: .rounded))
                .foregroundColor(theme.textPrimary)

            Text(subtitle)
                .font(.system(size: isIPad ? 14 : 12, weight: .medium, design: .rounded))
                .foregroundColor(theme.textSecondary)

            Text(title)
                .font(.system(size: isIPad ? 13 : 11, weight: .bold, design: .rounded))
                .foregroundColor(theme.textSecondary.opacity(0.7))
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isIPad ? 22 : 16)
        .background(theme.cardBackground)
        .cornerRadius(isIPad ? 20 : 16)
        .overlay(
            RoundedRectangle(cornerRadius: isIPad ? 20 : 16)
                .stroke(theme.textSecondary.opacity(0.1), lineWidth: 1)
        )
    }
}

private struct MonthlyStat: View {
    let label: String
    let value: String
    let theme: ColorTheme
    var isIPad: Bool = false

    var body: some View {
        VStack(spacing: isIPad ? 6 : 4) {
            Text(value)
                .font(.system(size: isIPad ? 22 : 18, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)
            Text(label)
                .font(.system(size: isIPad ? 13 : 11, weight: .medium, design: .rounded))
                .foregroundColor(theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    StreakHistoryView()
}
