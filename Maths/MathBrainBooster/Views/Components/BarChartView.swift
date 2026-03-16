import SwiftUI

struct BarChartView: View {
    let data: [Double]
    let labels: [String]
    let title: String
    let barColor: Color
    let theme: ColorTheme

    private var maxValue: Double {
        max(data.max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(theme.textPrimary)

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(data.enumerated()), id: \.offset) { index, value in
                    VStack(spacing: 4) {
                        Text(formatValue(value))
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(theme.textSecondary)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: [barColor.opacity(0.6), barColor],
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(height: max(4, CGFloat(value / maxValue) * 100))

                        if index < labels.count {
                            Text(labels[index])
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(theme.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 140)
            .padding(.top, 4)
        }
        .padding()
        .background(theme.cardBackground)
        .cornerRadius(16)
    }

    private func formatValue(_ value: Double) -> String {
        if value == value.rounded() {
            return "\(Int(value))"
        }
        return String(format: "%.0f", value)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        BarChartView(
            data: [120, 200, 150, 300, 180, 250, 190, 220, 280, 310],
            labels: ["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"],
            title: "Recent Scores",
            barColor: .blue,
            theme: .darkMode
        )
        .padding()
    }
}
