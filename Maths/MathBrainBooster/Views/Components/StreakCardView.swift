import SwiftUI

struct StreakCardView: View {
    @ObservedObject var streakMgr = StreakManager.shared
    let theme: ColorTheme
    let onViewHistory: () -> Void

    private var streakColor: Color {
        if streakMgr.currentStreak >= 7 {
            return Color(red: 1.0, green: 0.55, blue: 0.0) // Deep orange for big streaks
        } else if streakMgr.currentStreak >= 3 {
            return Color(red: 1.0, green: 0.7, blue: 0.0) // Warm amber
        } else {
            return Color(red: 1.0, green: 0.8, blue: 0.2) // Soft yellow
        }
    }

    private var streakMessage: String {
        switch streakMgr.currentStreak {
        case 0: return "Start your streak today!"
        case 1: return "Great start! Keep going!"
        case 2: return "2 days strong!"
        case 3...6: return "You're on fire!"
        case 7...13: return "One week streak!"
        case 14...29: return "Unstoppable!"
        case 30...: return "Legendary streak!"
        default: return "Keep it up!"
        }
    }

    var body: some View {
        VStack(spacing: 14) {
            // Top row: Streak info + View History
            HStack(alignment: .top) {
                // Flame icon
                ZStack {
                    Circle()
                        .fill(streakColor.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: streakMgr.currentStreak > 0 ? "flame.fill" : "flame")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(
                            streakMgr.currentStreak > 0
                            ? LinearGradient(colors: [Color(red: 1.0, green: 0.8, blue: 0.0), streakColor], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [theme.textSecondary, theme.textSecondary], startPoint: .top, endPoint: .bottom)
                        )
                        .symbolEffect(.bounce, value: streakMgr.currentStreak)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text("\(streakMgr.currentStreak) Day\(streakMgr.currentStreak == 1 ? "" : "s") Streak")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)

                    Text(streakMessage)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(theme.textSecondary)
                }

                Spacer()

                Button(action: onViewHistory) {
                    Text("View History")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(streakColor)
                }
            }

            // Weekly dots
            HStack(spacing: 0) {
                let weekStatus = streakMgr.currentWeekStatus()
                ForEach(0..<weekStatus.count, id: \.self) { i in
                    let day = weekStatus[i]
                    VStack(spacing: 6) {
                        Text(day.letter)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(day.isToday ? theme.textPrimary : theme.textSecondary)

                        ZStack {
                            if day.isActive {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [Color(red: 1.0, green: 0.8, blue: 0.0), streakColor],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            } else {
                                Circle()
                                    .fill(theme.textSecondary.opacity(0.2))
                                    .frame(width: 18, height: 18)
                            }
                        }
                        .frame(height: 22)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(theme.cardBackground)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(
                    LinearGradient(
                        colors: [streakColor.opacity(0.3), streakColor.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}
