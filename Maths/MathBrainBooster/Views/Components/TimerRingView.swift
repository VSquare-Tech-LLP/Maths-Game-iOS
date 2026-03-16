import SwiftUI

struct TimerRingView: View {
    let progress: CGFloat
    let color: Color
    let timeRemaining: TimeInterval
    var size: CGFloat = 100

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 8)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [color.opacity(0.6), color]),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360 * Double(progress))
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.05), value: progress)

            VStack(spacing: 2) {
                Text(String(format: "%.1f", max(0, timeRemaining)))
                    .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Text("sec")
                    .font(.system(size: size * 0.12, weight: .medium))
                    .opacity(0.7)
            }
            .foregroundColor(color)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 20) {
            TimerRingView(progress: 0.75, color: .green, timeRemaining: 7.5)
            TimerRingView(progress: 0.4, color: .yellow, timeRemaining: 4.0)
            TimerRingView(progress: 0.15, color: .red, timeRemaining: 1.5)
        }
    }
}
