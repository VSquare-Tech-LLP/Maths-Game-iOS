import SwiftUI

struct MagicSquareGameView: View {
    @ObservedObject var settings = SettingsViewModel.shared
    @Environment(\.dismiss) private var dismiss
    @State private var grid: [[Int]] = Array(repeating: Array(repeating: 0, count: 3), count: 3)
    @State private var fixed: [[Bool]] = Array(repeating: Array(repeating: false, count: 3), count: 3)
    @State private var solution: [[Int]] = []
    @State private var selectedRow = -1
    @State private var selectedCol = -1
    @State private var targetSum = 15
    @State private var level = 1
    @State private var score = 0
    @State private var isComplete = false
    @State private var showError = false
    @State private var availableNumbers: [Int] = []
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
                    Text("Magic Square")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                    HStack(spacing: 8) {
                        Button { isPaused = true } label: {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.textSecondary)
                                .frame(width: 36, height: 36)
                                .background(theme.cardBackground).cornerRadius(10)
                        }
                        Button { generatePuzzle() } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.textSecondary)
                                .frame(width: 36, height: 36)
                                .background(theme.cardBackground).cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)

                // Info
                HStack(spacing: 20) {
                    VStack(spacing: 2) {
                        Text("Level").font(.system(size: 11, weight: .medium)).foregroundColor(theme.textSecondary)
                        Text("\(level)").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(theme.primary)
                    }
                    VStack(spacing: 2) {
                        Text("Score").font(.system(size: 11, weight: .medium)).foregroundColor(theme.textSecondary)
                        Text("\(score)").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(theme.textPrimary)
                    }
                }

                // Target sum badge
                HStack(spacing: 6) {
                    Image(systemName: "sum")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Each row, column & diagonal = \(targetSum)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 16).padding(.vertical, 8)
                .background(Color.orange.opacity(0.15))
                .cornerRadius(12)

                Spacer()

                // 3x3 Grid with row sums on the right
                VStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { row in
                        HStack(spacing: 6) {
                            ForEach(0..<3, id: \.self) { col in
                                let val = grid[row][col]
                                let isFixed = fixed[row][col]
                                let isSelected = selectedRow == row && selectedCol == col

                                Button {
                                    if !isFixed {
                                        selectedRow = row
                                        selectedCol = col
                                        showError = false
                                    }
                                } label: {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(
                                                isSelected ? theme.primary.opacity(0.2) :
                                                isFixed ? theme.cardBackground :
                                                val > 0 ? theme.primary.opacity(0.08) :
                                                theme.primary.opacity(0.05)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(
                                                        isSelected ? theme.primary :
                                                        val > 0 && !isFixed ? Color.blue.opacity(0.3) :
                                                        theme.textSecondary.opacity(0.2),
                                                        lineWidth: isSelected ? 2 : 1
                                                    )
                                            )

                                        if val > 0 {
                                            Text("\(val)")
                                                .font(.system(size: 32, weight: isFixed ? .heavy : .bold, design: .rounded))
                                                .foregroundColor(isFixed ? theme.textPrimary : .blue)
                                        }
                                    }
                                    .aspectRatio(1, contentMode: .fit)
                                }
                                .disabled(isFixed)
                            }

                            // Row sum indicator
                            let rowSum = grid[row][0] + grid[row][1] + grid[row][2]
                            let isRowComplete = grid[row][0] > 0 && grid[row][1] > 0 && grid[row][2] > 0
                            let isRowCorrect = isRowComplete && rowSum == targetSum
                            Text(rowSum > 0 ? "\(rowSum)" : "-")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(isRowCorrect ? .green : isRowComplete ? .red : theme.textSecondary)
                                .frame(width: 32)
                        }
                    }

                    // Column sums
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { col in
                            let colSum = grid[0][col] + grid[1][col] + grid[2][col]
                            let isColComplete = grid[0][col] > 0 && grid[1][col] > 0 && grid[2][col] > 0
                            let isCorrectCol = isColComplete && colSum == targetSum
                            Text(colSum > 0 ? "\(colSum)" : "-")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(isCorrectCol ? .green : isColComplete ? .red : theme.textSecondary)
                                .frame(maxWidth: .infinity)
                        }
                        Color.clear.frame(width: 32)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 40)

                Spacer()

                // Available numbers
                VStack(spacing: 8) {
                    Text("Available Numbers")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.textSecondary)

                    // Wrap numbers in rows if needed
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: min(availableNumbers.count, 6)), spacing: 6) {
                        ForEach(availableNumbers, id: \.self) { num in
                            let isUsed = isNumberUsed(num)
                            Button {
                                placeNumber(num)
                            } label: {
                                Text("\(num)")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(isUsed ? theme.textSecondary.opacity(0.3) : theme.textPrimary)
                                    .frame(width: 44, height: 44)
                                    .background(isUsed ? theme.cardBackground.opacity(0.5) : theme.cardBackground)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(isUsed ? Color.clear : theme.primary.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            .disabled(isUsed || selectedRow < 0)
                        }
                    }
                    .padding(.horizontal, 20)

                    // Action buttons row
                    HStack(spacing: 12) {
                        // Erase selected cell
                        Button {
                            eraseSelected()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "delete.left.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Erase")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(canErase ? theme.textPrimary : theme.textSecondary.opacity(0.4))
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(theme.cardBackground).cornerRadius(10)
                        }
                        .disabled(!canErase)

                        // Clear all user-placed numbers
                        Button {
                            clearAllUserNumbers()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Clear All")
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.red.opacity(0.8))
                            .padding(.horizontal, 16).padding(.vertical, 10)
                            .background(theme.cardBackground).cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)

                // Check button
                Button {
                    checkSolution()
                } label: {
                    Text("Check Solution")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 14)
                        .background(
                            allFilled
                            ? LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)
                            : LinearGradient(colors: [Color.gray, Color.gray], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(14)
                }
                .disabled(!allFilled)
                .padding(.horizontal)

                if showError {
                    Text("Not quite right - keep trying!")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.red)
                }

                Spacer().frame(height: 8)
            }
            .padding(.top, 8)

            if isComplete { completionOverlay }

            if isPaused {
                MiniGamePauseOverlay(
                    theme: theme,
                    onResume: { isPaused = false },
                    onRestart: { isPaused = false; generatePuzzle() },
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
        .onAppear { generatePuzzle() }
    }

    // MARK: - Computed Properties

    private var allFilled: Bool {
        for r in 0..<3 { for c in 0..<3 { if grid[r][c] == 0 { return false } } }
        return true
    }

    private var canErase: Bool {
        selectedRow >= 0 && selectedCol >= 0 &&
        !fixed[selectedRow][selectedCol] &&
        grid[selectedRow][selectedCol] > 0
    }

    // MARK: - Number Management (FIXED: excludes selected cell from "used" check)

    private func isNumberUsed(_ num: Int) -> Bool {
        for r in 0..<3 {
            for c in 0..<3 {
                // Skip the currently selected cell - user should be able to replace it
                if r == selectedRow && c == selectedCol { continue }
                if grid[r][c] == num { return true }
            }
        }
        return false
    }

    private func placeNumber(_ num: Int) {
        guard selectedRow >= 0, selectedCol >= 0, !fixed[selectedRow][selectedCol] else { return }
        grid[selectedRow][selectedCol] = num
        showError = false
        HapticManager.shared.buttonTap()
    }

    private func eraseSelected() {
        guard selectedRow >= 0, selectedCol >= 0, !fixed[selectedRow][selectedCol] else { return }
        grid[selectedRow][selectedCol] = 0
        showError = false
        HapticManager.shared.buttonTap()
    }

    private func clearAllUserNumbers() {
        for r in 0..<3 {
            for c in 0..<3 {
                if !fixed[r][c] {
                    grid[r][c] = 0
                }
            }
        }
        selectedRow = -1
        selectedCol = -1
        showError = false
        HapticManager.shared.buttonTap()
    }

    // MARK: - Puzzle Generation

    private func generatePuzzle() {
        isComplete = false; showError = false; selectedRow = -1; selectedCol = -1

        // Classic magic square base: multiplied by level factor
        let base = [[2, 7, 6], [9, 5, 1], [4, 3, 8]]
        let factor = level <= 2 ? 1 : Int.random(in: 1...level)
        let offset = level <= 1 ? 0 : Int.random(in: 0...(level * 2))

        solution = base.map { row in row.map { $0 * factor + offset } }
        targetSum = solution[0].reduce(0, +)

        grid = solution
        fixed = Array(repeating: Array(repeating: true, count: 3), count: 3)

        // Hide cells based on level
        let cellsToHide = min(3 + level, 7)
        var hidden = 0
        var attempts = 0
        while hidden < cellsToHide && attempts < 50 {
            let r = Int.random(in: 0..<3)
            let c = Int.random(in: 0..<3)
            if fixed[r][c] {
                grid[r][c] = 0
                fixed[r][c] = false
                hidden += 1
            }
            attempts += 1
        }

        // Available numbers = all solution numbers
        availableNumbers = solution.flatMap { $0 }.sorted()
    }

    // MARK: - Solution Check

    private func checkSolution() {
        // Check rows, cols, diagonals
        for r in 0..<3 {
            if grid[r].reduce(0, +) != targetSum { showError = true; SoundManager.shared.playWrong(); HapticManager.shared.wrongAnswer(); return }
        }
        for c in 0..<3 {
            if grid[0][c] + grid[1][c] + grid[2][c] != targetSum { showError = true; SoundManager.shared.playWrong(); HapticManager.shared.wrongAnswer(); return }
        }
        if grid[0][0] + grid[1][1] + grid[2][2] != targetSum { showError = true; SoundManager.shared.playWrong(); HapticManager.shared.wrongAnswer(); return }
        if grid[0][2] + grid[1][1] + grid[2][0] != targetSum { showError = true; SoundManager.shared.playWrong(); HapticManager.shared.wrongAnswer(); return }

        // Correct!
        isComplete = true
        score += level * 25
        SoundManager.shared.playAchievement()
        HapticManager.shared.achievement()
    }

    // MARK: - Overlays

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 56)).foregroundColor(.green)
                Text("Magic!").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(theme.textPrimary)
                Text("Score: \(score)").font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundColor(.orange)
                VStack(spacing: 12) {
                    Button { level += 1; generatePuzzle() } label: {
                        HStack { Image(systemName: "arrow.right"); Text("Next Level") }
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(LinearGradient(colors: [.orange, .red], startPoint: .leading, endPoint: .trailing)).cornerRadius(14)
                    }
                    Button { dismiss() } label: {
                        Text("Back to Games").font(.system(size: 16, weight: .semibold, design: .rounded))
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

#Preview { MagicSquareGameView() }
