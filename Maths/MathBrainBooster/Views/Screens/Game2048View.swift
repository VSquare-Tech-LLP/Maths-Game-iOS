import SwiftUI

struct Game2048View: View {
    @ObservedObject var settings = SettingsViewModel.shared
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = Game2048VM()
    @State private var isPaused = false

    private var theme: ColorTheme { settings.selectedTheme }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 16) {
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

                    VStack(spacing: 2) {
                        Text("2048")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(theme.textPrimary)
                    }

                    Spacer()

                    HStack(spacing: 8) {
                        Button { isPaused = true } label: {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.textSecondary)
                                .frame(width: 36, height: 36)
                                .background(theme.cardBackground).cornerRadius(10)
                        }

                        Button { vm.reset() } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.textSecondary)
                                .frame(width: 36, height: 36)
                                .background(theme.cardBackground).cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)

                // Score + Undo
                HStack(spacing: 12) {
                    scoreBox(title: "SCORE", value: vm.score)
                    scoreBox(title: "BEST", value: vm.bestScore)

                    // Undo button
                    Button {
                        vm.undo()
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.uturn.backward")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(vm.canUndo ? theme.primary : theme.textSecondary.opacity(0.3))
                            Text("UNDO")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundColor(vm.canUndo ? theme.primary : theme.textSecondary.opacity(0.3))
                        }
                        .frame(width: 65)
                        .padding(.vertical, 10)
                        .background(theme.cardBackground)
                        .cornerRadius(12)
                    }
                    .disabled(!vm.canUndo)
                }
                .padding(.horizontal)

                // Grid
                gridView
                    .padding(.horizontal)
                    .gesture(
                        DragGesture(minimumDistance: 30)
                            .onEnded { value in
                                let h = value.translation.width
                                let v = value.translation.height
                                if abs(h) > abs(v) {
                                    vm.move(h > 0 ? .right : .left)
                                } else {
                                    vm.move(v > 0 ? .down : .up)
                                }
                            }
                    )

                // Swipe hint
                Text("Swipe to move tiles")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(theme.textSecondary)

                Spacer()
            }
            .padding(.top, 8)

            if vm.gameOver {
                gameOverOverlay
            }

            if vm.won && !vm.continuePlaying {
                wonOverlay
            }

            if isPaused {
                MiniGamePauseOverlay(
                    theme: theme,
                    onResume: { isPaused = false },
                    onRestart: { isPaused = false; vm.reset() },
                    onGameSelection: { isPaused = false; dismiss() },
                    onHome: {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(name: .miniGameGoHome, object: nil)
                        }
                    }
                )
            }
        }
        .onAppear {
            if vm.score == 0 { vm.reset() }
        }
    }

    private func scoreBox(title: String, value: Int) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(theme.textSecondary)
            Text("\(value)")
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(theme.textPrimary)
                .contentTransition(.numericText())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(theme.cardBackground)
        .cornerRadius(12)
    }

    private var gridView: some View {
        VStack(spacing: 6) {
            ForEach(0..<4, id: \.self) { row in
                HStack(spacing: 6) {
                    ForEach(0..<4, id: \.self) { col in
                        let val = vm.grid[row][col]
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(tileColor(val))

                            if val > 0 {
                                Text("\(val)")
                                    .font(.system(size: val >= 1000 ? 20 : val >= 100 ? 24 : 28, weight: .bold, design: .rounded))
                                    .foregroundColor(val <= 4 ? Color(white: 0.4) : .white)
                                    .minimumScaleFactor(0.5)
                            }
                        }
                        .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .padding(8)
        .background(theme.textSecondary.opacity(0.15))
        .cornerRadius(12)
    }

    private func tileColor(_ value: Int) -> Color {
        switch value {
        case 0:    return theme.cardBackground
        case 2:    return Color(red: 0.93, green: 0.89, blue: 0.85)
        case 4:    return Color(red: 0.93, green: 0.87, blue: 0.78)
        case 8:    return Color(red: 0.95, green: 0.69, blue: 0.47)
        case 16:   return Color(red: 0.96, green: 0.58, blue: 0.39)
        case 32:   return Color(red: 0.96, green: 0.49, blue: 0.37)
        case 64:   return Color(red: 0.96, green: 0.37, blue: 0.23)
        case 128:  return Color(red: 0.93, green: 0.81, blue: 0.45)
        case 256:  return Color(red: 0.93, green: 0.80, blue: 0.38)
        case 512:  return Color(red: 0.93, green: 0.78, blue: 0.31)
        case 1024: return Color(red: 0.93, green: 0.76, blue: 0.18)
        case 2048: return Color(red: 0.93, green: 0.74, blue: 0.0)
        default:   return Color(red: 0.24, green: 0.23, blue: 0.20)
        }
    }

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 20) {
                Text("Game Over!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                Text("Score: \(vm.score)")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.orange)
                VStack(spacing: 12) {
                    Button { vm.reset() } label: {
                        HStack { Image(systemName: "arrow.counterclockwise"); Text("Try Again") }
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)).cornerRadius(14)
                    }
                    Button { dismiss() } label: {
                        Text("Back to Games")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(theme.textPrimary).frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(theme.cardBackground).cornerRadius(14)
                    }
                }
            }
            .padding(28)
            .background(RoundedRectangle(cornerRadius: 24).fill(theme.background).shadow(color: .black.opacity(0.3), radius: 20, y: 10))
            .padding(.horizontal, 32)
        }
    }

    private var wonOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "star.fill")
                    .font(.system(size: 48)).foregroundColor(.yellow)
                Text("You Win!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                Text("Score: \(vm.score)")
                    .font(.system(size: 20, weight: .heavy, design: .rounded)).foregroundColor(.orange)
                VStack(spacing: 12) {
                    Button { vm.continuePlaying = true } label: {
                        Text("Continue Playing")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)).cornerRadius(14)
                    }
                    Button { vm.reset() } label: {
                        Text("New Game")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(theme.textPrimary).frame(maxWidth: .infinity).padding(.vertical, 14)
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

// MARK: - 2048 ViewModel

@MainActor
final class Game2048VM: ObservableObject {
    enum Direction { case up, down, left, right }

    @Published var grid: [[Int]] = Array(repeating: Array(repeating: 0, count: 4), count: 4)
    @Published var score = 0
    @Published var bestScore = 0
    @Published var gameOver = false
    @Published var won = false
    @Published var continuePlaying = false
    @Published var canUndo = false

    // Undo state
    private var previousGrid: [[Int]] = []
    private var previousScore = 0

    private let bestKey = "game2048Best"

    init() {
        bestScore = UserDefaults.standard.integer(forKey: bestKey)
    }

    func reset() {
        grid = Array(repeating: Array(repeating: 0, count: 4), count: 4)
        score = 0; gameOver = false; won = false; continuePlaying = false; canUndo = false
        previousGrid = []; previousScore = 0
        addRandom(); addRandom()
    }

    func undo() {
        guard canUndo else { return }
        grid = previousGrid
        score = previousScore
        gameOver = false
        canUndo = false
        HapticManager.shared.buttonTap()
    }

    func move(_ dir: Direction) {
        guard !gameOver, !(won && !continuePlaying) else { return }
        let old = grid
        let oldScore = score

        switch dir {
        case .left:  moveLeft()
        case .right: grid = grid.map { $0.reversed() }; moveLeft(); grid = grid.map { $0.reversed() }
        case .up:    transpose(); moveLeft(); transpose()
        case .down:  transpose(); grid = grid.map { $0.reversed() }; moveLeft(); grid = grid.map { $0.reversed() }; transpose()
        }

        if grid != old {
            // Save undo state
            previousGrid = old
            previousScore = oldScore
            canUndo = true

            addRandom()
            HapticManager.shared.buttonTap()
            if score > bestScore {
                bestScore = score
                UserDefaults.standard.set(bestScore, forKey: bestKey)
            }
            checkGameState()
        }
    }

    private func moveLeft() {
        for r in 0..<4 {
            let row = grid[r].filter { $0 != 0 }
            var merged: [Int] = []
            var i = 0
            while i < row.count {
                if i + 1 < row.count && row[i] == row[i + 1] {
                    let val = row[i] * 2
                    merged.append(val)
                    score += val
                    if val == 2048 && !won && !continuePlaying { won = true; StreakManager.shared.recordActivity() }
                    i += 2
                } else {
                    merged.append(row[i])
                    i += 1
                }
            }
            while merged.count < 4 { merged.append(0) }
            grid[r] = merged
        }
    }

    private func transpose() {
        var new = grid
        for r in 0..<4 { for c in 0..<4 { new[c][r] = grid[r][c] } }
        grid = new
    }

    private func addRandom() {
        var empty: [(Int, Int)] = []
        for r in 0..<4 { for c in 0..<4 { if grid[r][c] == 0 { empty.append((r, c)) } } }
        guard let pos = empty.randomElement() else { return }
        grid[pos.0][pos.1] = Double.random(in: 0...1) < 0.9 ? 2 : 4
    }

    private func checkGameState() {
        // Check if any move possible
        for r in 0..<4 {
            for c in 0..<4 {
                if grid[r][c] == 0 { return }
                if c + 1 < 4 && grid[r][c] == grid[r][c + 1] { return }
                if r + 1 < 4 && grid[r][c] == grid[r + 1][c] { return }
            }
        }
        gameOver = true
        StreakManager.shared.recordActivity()
        SoundManager.shared.playGameOver()
        HapticManager.shared.gameOver()
    }
}

#Preview { Game2048View() }
