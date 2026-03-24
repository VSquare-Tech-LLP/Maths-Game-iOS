import SwiftUI

enum MPGridSize: String, CaseIterable {
    case four = "4 x 4"
    case six = "6 x 6"

    var columns: Int {
        switch self {
        case .four: return 4
        case .six:  return 6
        }
    }

    var totalCards: Int { columns * columns }
    var pairs: Int { totalCards / 2 }
    var previewTime: Int {
        switch self {
        case .four: return 3
        case .six:  return 5
        }
    }
}

struct MathPairsGameView: View {
    @ObservedObject var settings = SettingsViewModel.shared
    @Environment(\.dismiss) private var dismiss
    @State private var cards: [MPCard] = []
    @State private var flippedIndices: [Int] = []
    @State private var matchedIds: Set<UUID> = []
    @State private var cardRotations: [Double] = []
    @State private var moves = 0
    @State private var pairsFound = 0
    @State private var totalPairs = 0
    @State private var isComplete = false
    @State private var isProcessing = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var isPaused = false
    @State private var isPreviewPhase = true
    @State private var previewCountdown = 3
    @State private var gridSize: MPGridSize = .four
    @State private var isPlaying = false  // false = show size picker

    private var theme: ColorTheme { settings.selectedTheme }

    struct MPCard: Identifiable {
        let id = UUID()
        let text: String
        let answer: Int      // the numeric answer this card represents
        let isEquation: Bool  // true = equation card, false = answer card
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            if !isPlaying {
                gridSizePicker
            } else {
                gameContent
            }

            if isComplete { completionOverlay }

            if isPaused {
                MiniGamePauseOverlay(
                    theme: theme,
                    onResume: {
                        isPaused = false
                        if !isPreviewPhase { startTimer() }
                    },
                    onRestart: {
                        isPaused = false
                        setupGame()
                    },
                    onGameSelection: {
                        isPaused = false
                        timer?.invalidate()
                        dismiss()
                    },
                    onHome: {
                        timer?.invalidate()
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(name: .miniGameGoHome, object: nil)
                        }
                    }
                )
            }
        }
    }

    // MARK: - Grid Size Picker

    private var gridSizePicker: some View {
        VStack(spacing: 24) {
            // Top bar
            HStack {
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(theme.cardBackground).cornerRadius(10)
                }
                Spacer()
                Text("Math Pairs")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                Spacer()
                Color.clear.frame(width: 36, height: 36)
            }
            .padding(.horizontal)

            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                Image(systemName: "rectangle.on.rectangle")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
            }

            Text("Choose Grid Size")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)

            // Grid size options
            HStack(spacing: 16) {
                ForEach(MPGridSize.allCases, id: \.self) { size in
                    let isSelected = gridSize == size
                    Button {
                        gridSize = size
                    } label: {
                        VStack(spacing: 8) {
                            // Mini grid preview
                            gridPreview(size: size)

                            Text(size.rawValue)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(isSelected ? .white : theme.textPrimary)

                            Text("\(size.pairs) pairs")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(isSelected ? .white.opacity(0.8) : theme.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            isSelected
                            ? AnyShapeStyle(LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                            : AnyShapeStyle(theme.cardBackground)
                        )
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(isSelected ? Color.clear : theme.textSecondary.opacity(0.15), lineWidth: 1)
                        )
                    }
                }
            }
            .padding(.horizontal, 24)

            // Start button
            Button {
                isPlaying = true
                setupGame()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                    Text("Start Game")
                }
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity).padding(.vertical, 16)
                .background(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(16)
            }
            .padding(.horizontal, 24)

            Spacer()
        }
        .padding(.top, 8)
    }

    private func gridPreview(size: MPGridSize) -> some View {
        let cols = size == .four ? 4 : 5  // visual preview cols
        let rows = size == .four ? 4 : 5
        return VStack(spacing: 2) {
            ForEach(0..<rows, id: \.self) { _ in
                HStack(spacing: 2) {
                    ForEach(0..<cols, id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(gridSize == size ? Color.white.opacity(0.4) : theme.primary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
    }

    // MARK: - Game Content

    private var gameContent: some View {
        VStack(spacing: 10) {
            // Top bar
            HStack {
                Button { timer?.invalidate(); dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(theme.cardBackground).cornerRadius(10)
                }
                Spacer()
                Text("Math Pairs")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                Spacer()
                HStack(spacing: 8) {
                    Button {
                        isPaused = true
                        timer?.invalidate()
                    } label: {
                        Image(systemName: "pause.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(theme.cardBackground).cornerRadius(10)
                    }
                    Button {
                        isPlaying = false
                        timer?.invalidate()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.textSecondary)
                            .frame(width: 36, height: 36)
                            .background(theme.cardBackground).cornerRadius(10)
                    }
                }
            }
            .padding(.horizontal)

            // Stats
            HStack(spacing: 16) {
                statBadge(icon: "hand.tap", value: "\(moves)")
                statBadge(icon: "square.2.layers.3d", value: "\(pairsFound)/\(totalPairs)")
                statBadge(icon: "clock", value: formatTime(elapsedTime))
                statBadge(icon: "square.grid.2x2", value: gridSize.rawValue)
            }
            .padding(.horizontal)

            // Preview countdown banner
            if isPreviewPhase {
                HStack(spacing: 6) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Memorize! \(previewCountdown)s")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16).padding(.vertical, 6)
                .background(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing))
                .cornerRadius(12)
            }

            Spacer()

            // Card grid
            let cols = Array(repeating: GridItem(.flexible(), spacing: gridSize == .four ? 10 : 6), count: gridSize.columns)
            LazyVGrid(columns: cols, spacing: gridSize == .four ? 10 : 6) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    let isFaceUp = flippedIndices.contains(index) || isPreviewPhase || matchedIds.contains(card.id)
                    let isMatched = matchedIds.contains(card.id)

                    Button {
                        flipCard(at: index)
                    } label: {
                        flipCardView(card: card, index: index, isFaceUp: isFaceUp, isMatched: isMatched)
                    }
                    .disabled(isFaceUp || isProcessing || isPaused || isPreviewPhase)
                }
            }
            .padding(.horizontal, gridSize == .four ? 12 : 6)

            Spacer()
        }
        .padding(.top, 8)
    }

    // MARK: - 3D Flip Card View

    private func flipCardView(card: MPCard, index: Int, isFaceUp: Bool, isMatched: Bool) -> some View {
        let rotation = index < cardRotations.count ? cardRotations[index] : 0
        let cardHeight: CGFloat = gridSize == .four ? 80 : 48
        let fontSize: CGFloat = gridSize == .four ? 20 : 13
        let qFontSize: CGFloat = gridSize == .four ? 24 : 16
        let radius: CGFloat = gridSize == .four ? 14 : 10

        return ZStack {
            // Back face
            ZStack {
                RoundedRectangle(cornerRadius: radius)
                    .fill(LinearGradient(colors: [.green, .mint], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(
                        RoundedRectangle(cornerRadius: radius)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
                Image(systemName: "questionmark")
                    .font(.system(size: qFontSize, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
            }
            .opacity(rotation < 90 ? 1 : 0)

            // Front face
            ZStack {
                RoundedRectangle(cornerRadius: radius)
                    .fill(frontFill(isMatched: isMatched))
                    .overlay(
                        RoundedRectangle(cornerRadius: radius)
                            .stroke(isMatched ? Color.green.opacity(0.6) : theme.primary.opacity(0.2), lineWidth: 1.5)
                    )
                Text(card.text)
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .foregroundColor(isMatched ? .green : theme.textPrimary)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .padding(.horizontal, 4)
            }
            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            .opacity(rotation >= 90 ? 1 : 0)
        }
        .frame(height: cardHeight)
        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
    }

    private func frontFill(isMatched: Bool) -> some ShapeStyle {
        if isMatched {
            return AnyShapeStyle(Color.green.opacity(0.25))
        } else {
            return AnyShapeStyle(theme.cardBackground)
        }
    }

    private func statBadge(icon: String, value: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(theme.primary)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(theme.cardBackground).cornerRadius(10)
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let m = Int(t) / 60; let s = Int(t) % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - Flip Animations

    private func animateFlipToFront(_ index: Int) {
        guard index < cardRotations.count else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            cardRotations[index] = 180
        }
    }

    private func animateFlipToBack(_ index: Int) {
        guard index < cardRotations.count else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            cardRotations[index] = 0
        }
    }

    private func animateAllToFront() {
        for i in 0..<cardRotations.count {
            withAnimation(.easeInOut(duration: 0.4).delay(Double(i) * 0.02)) {
                cardRotations[i] = 180
            }
        }
    }

    private func animateAllToBack() {
        for i in 0..<cardRotations.count {
            withAnimation(.easeInOut(duration: 0.4).delay(Double(i) * 0.02)) {
                cardRotations[i] = 0
            }
        }
    }

    // MARK: - Game Logic

    private func setupGame() {
        matchedIds.removeAll()
        flippedIndices.removeAll()
        moves = 0; pairsFound = 0; isComplete = false; isProcessing = false; elapsedTime = 0
        isPreviewPhase = true; previewCountdown = gridSize.previewTime
        timer?.invalidate()

        let pairCount = gridSize.pairs

        // Generate pairs with UNIQUE answers so no ambiguity
        var pairs: [MPCard] = []
        var usedAnswers = Set<Int>()

        while pairs.count < pairCount * 2 {
            let a = Int.random(in: 2...12)
            let b = Int.random(in: 2...12)
            let ops = ["+", "-", "x"]
            let op = ops.randomElement()!
            var result: Int
            var eq: String
            switch op {
            case "+": result = a + b; eq = "\(a) + \(b)"
            case "-": let big = max(a, b); let small = min(a, b); result = big - small; eq = "\(big) - \(small)"
            default:  result = a * b; eq = "\(a) x \(b)"
            }

            // Skip if this answer already exists (prevents duplicate answer cards)
            if usedAnswers.contains(result) { continue }
            usedAnswers.insert(result)

            pairs.append(MPCard(text: eq, answer: result, isEquation: true))
            pairs.append(MPCard(text: "\(result)", answer: result, isEquation: false))
        }
        cards = pairs.shuffled()
        totalPairs = pairCount

        cardRotations = Array(repeating: 0, count: cards.count)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            animateAllToFront()
        }

        startPreviewCountdown()
    }

    private func startPreviewCountdown() {
        previewCountdown = gridSize.previewTime
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            Task { @MainActor in
                previewCountdown -= 1
                if previewCountdown <= 0 {
                    t.invalidate()
                    isPreviewPhase = false
                    animateAllToBack()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        startTimer()
                    }
                }
            }
        }
    }

    private func flipCard(at index: Int) {
        guard !isProcessing, !isPaused, !isPreviewPhase else { return }
        flippedIndices.append(index)
        animateFlipToFront(index)
        HapticManager.shared.buttonTap()

        if flippedIndices.count == 2 {
            moves += 1
            isProcessing = true
            let i1 = flippedIndices[0], i2 = flippedIndices[1]
            let card1 = cards[i1], card2 = cards[i2]

            // Match: one must be equation, other must be answer, and same answer value
            let isMatch = card1.answer == card2.answer &&
                          card1.isEquation != card2.isEquation

            if isMatch {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    matchedIds.insert(cards[i1].id)
                    matchedIds.insert(cards[i2].id)
                    flippedIndices.removeAll()
                    pairsFound += 1
                    isProcessing = false
                    SoundManager.shared.playCorrect()
                    HapticManager.shared.correctAnswer()
                    if pairsFound == totalPairs {
                        isComplete = true
                        timer?.invalidate()
                        StreakManager.shared.recordActivity()
                        SoundManager.shared.playAchievement()
                        HapticManager.shared.achievement()
                    }
                }
            } else {
                SoundManager.shared.playWrong()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    animateFlipToBack(i1)
                    animateFlipToBack(i2)
                    flippedIndices.removeAll()
                    isProcessing = false
                }
            }
        }
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in elapsedTime += 1 }
        }
    }

    // MARK: - Completion Overlay

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 56)).foregroundColor(.green)
                Text("All Matched!").font(.system(size: 26, weight: .bold, design: .rounded)).foregroundColor(theme.textPrimary)
                HStack(spacing: 20) {
                    VStack { Text("\(moves)").font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(.green); Text("Moves").font(.system(size: 12)).foregroundColor(theme.textSecondary) }
                    VStack { Text(formatTime(elapsedTime)).font(.system(size: 22, weight: .bold, design: .rounded)).foregroundColor(.blue); Text("Time").font(.system(size: 12)).foregroundColor(theme.textSecondary) }
                }
                VStack(spacing: 12) {
                    Button { setupGame() } label: {
                        HStack { Image(systemName: "arrow.counterclockwise"); Text("Play Again") }
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing)).cornerRadius(14)
                    }
                    Button { dismiss() } label: {
                        Text("Back to Games").font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(theme.textSecondary).frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(theme.cardBackground).cornerRadius(14)
                    }
                }
            }
            .padding(28)
            .background(RoundedRectangle(cornerRadius: 24).fill(theme.background).shadow(color: .black.opacity(0.3), radius: 20, y: 10))
            .padding(.horizontal, 32)
        }
    }
}

#Preview { MathPairsGameView() }
