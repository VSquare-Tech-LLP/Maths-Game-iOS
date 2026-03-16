import SwiftUI

struct AnswerButtonView: View {
    let answer: Int
    let isTrueFalse: Bool
    let isSelected: Bool
    let isCorrect: Bool?
    let showFeedback: Bool
    let theme: ColorTheme
    let action: () -> Void

    private var displayText: String {
        if isTrueFalse {
            return answer == 1 ? "TRUE" : "FALSE"
        }
        return "\(answer)"
    }

    private var backgroundColor: Color {
        if showFeedback && isSelected {
            return isCorrect == true ? Color.green : Color.red
        }
        if showFeedback && isCorrect == true && !isSelected {
            return Color.green.opacity(0.4)
        }
        return theme.cardBackground
    }

    private var borderColor: Color {
        if showFeedback && isSelected {
            return isCorrect == true ? Color.green : Color.red
        }
        return theme.primary.opacity(0.3)
    }

    var body: some View {
        Button(action: action) {
            Text(displayText)
                .font(.system(size: isTrueFalse ? 22 : 28, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: isTrueFalse ? 60 : 72)
                .background(backgroundColor)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(borderColor, lineWidth: 2)
                )
                .scaleEffect(isSelected && showFeedback ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.15), value: showFeedback)
        }
        .disabled(showFeedback)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack(spacing: 12) {
            AnswerButtonView(answer: 42, isTrueFalse: false, isSelected: false, isCorrect: nil, showFeedback: false, theme: .darkMode) {}
            AnswerButtonView(answer: 42, isTrueFalse: false, isSelected: true, isCorrect: true, showFeedback: true, theme: .darkMode) {}
            AnswerButtonView(answer: 1, isTrueFalse: true, isSelected: false, isCorrect: nil, showFeedback: false, theme: .darkMode) {}
        }
        .padding()
    }
}
