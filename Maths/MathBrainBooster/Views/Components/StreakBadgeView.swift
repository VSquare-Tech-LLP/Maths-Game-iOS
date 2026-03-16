import SwiftUI

struct StreakBadgeView: View {
    let streak: Int
    let multiplier: Int
    let theme: ColorTheme

    var body: some View {
        if streak >= 3 {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16))
                    .symbolEffect(.bounce, value: streak)

                Text("\(streak)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)

                if multiplier > 1 {
                    Text("×\(multiplier)")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(multiplierColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(multiplierColor.opacity(0.2))
                        .cornerRadius(6)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(theme.cardBackground)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.orange.opacity(0.4), lineWidth: 1)
            )
            .transition(.scale.combined(with: .opacity))
        }
    }

    private var multiplierColor: Color {
        switch multiplier {
        case 3: return .red
        case 2: return .orange
        default: return .yellow
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 12) {
            StreakBadgeView(streak: 5, multiplier: 2, theme: .darkMode)
            StreakBadgeView(streak: 12, multiplier: 3, theme: .darkMode)
        }
    }
}
