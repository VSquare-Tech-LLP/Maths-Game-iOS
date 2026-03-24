import SwiftUI

struct MagicSquareGameView: View {
    @ObservedObject var settings = SettingsViewModel.shared
    @Environment(\.dismiss) private var dismiss
    @State private var gridSize = 3
    @State private var grid: [[Int]] = Array(repeating: Array(repeating: 0, count: 3), count: 3)
    @State private var fixed: [[Bool]] = Array(repeating: Array(repeating: false, count: 3), count: 3)
    @State private var solution: [[Int]] = Array(repeating: Array(repeating: 0, count: 3), count: 3)
    @State private var selectedRow = -1
    @State private var selectedCol = -1
    @State private var targetSum = 15
    @State private var level = 1
    @State private var score = 0
    @State private var isComplete = false
    @State private var availableNumbers: [Int] = []
    @State private var isPaused = false

    private var theme: ColorTheme { settings.selectedTheme }

    private let maxLevel = 50

    /// Grid size based on level: 3x3 for levels 1-15, 4x4 for levels 16-35, 5x5 for levels 36-50
    private var gridSizeForLevel: Int {
        if level >= 36 { return 5 }
        if level >= 16 { return 4 }
        return 3
    }

    /// Grid size for the next level (used in completion overlay)
    private var nextGridSize: Int {
        let next = level >= maxLevel ? 1 : level + 1
        if next >= 36 { return 5 }
        if next >= 16 { return 4 }
        return 3
    }

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            VStack(spacing: 12) {
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
                    VStack(spacing: 2) {
                        Text("Grid").font(.system(size: 11, weight: .medium)).foregroundColor(theme.textSecondary)
                        Text("\(gridSize)×\(gridSize)").font(.system(size: 20, weight: .bold, design: .rounded)).foregroundColor(theme.textPrimary)
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

                // Dynamic Grid with row sums
                VStack(spacing: gridSize >= 5 ? 4 : 6) {
                    ForEach(0..<gridSize, id: \.self) { row in
                        HStack(spacing: gridSize >= 5 ? 4 : 6) {
                            ForEach(0..<gridSize, id: \.self) { col in
                                gridCell(row: row, col: col)
                            }

                            // Row sum indicator
                            rowSumIndicator(row: row)
                        }
                    }

                    // Column sums
                    HStack(spacing: gridSize >= 5 ? 4 : 6) {
                        ForEach(0..<gridSize, id: \.self) { col in
                            colSumIndicator(col: col)
                        }
                        Color.clear.frame(width: 32)
                    }
                    .padding(.top, 4)

                    // Diagonal sums
                    HStack(spacing: 12) {
                        diagonalIndicator(isDiag1: true)
                        diagonalIndicator(isDiag1: false)
                    }
                    .padding(.top, 2)
                }
                .padding(.horizontal, gridSize >= 5 ? 16 : gridSize >= 4 ? 24 : 40)

                Spacer()

                // Available numbers
                VStack(spacing: 8) {
                    Text("Available Numbers")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(theme.textSecondary)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: min(availableNumbers.count, gridSize >= 5 ? 8 : 6)), spacing: 6) {
                        ForEach(availableNumbers, id: \.self) { num in
                            let isUsed = isNumberUsed(num)
                            Button {
                                placeNumber(num)
                            } label: {
                                Text("\(num)")
                                    .font(.system(size: gridSize >= 5 ? 16 : 20, weight: .bold, design: .rounded))
                                    .foregroundColor(isUsed ? theme.textSecondary.opacity(0.3) : theme.textPrimary)
                                    .frame(width: gridSize >= 5 ? 36 : 44, height: gridSize >= 5 ? 36 : 44)
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

    // MARK: - Grid Cell View

    @ViewBuilder
    private func gridCell(row: Int, col: Int) -> some View {
        let val = grid[row][col]
        let isFixed = fixed[row][col]
        let isSelected = selectedRow == row && selectedCol == col
        let cellFontSize: CGFloat = gridSize >= 5 ? 20 : gridSize >= 4 ? 26 : 32

        Button {
            if !isFixed {
                selectedRow = row
                selectedCol = col
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: gridSize >= 5 ? 8 : 12)
                    .fill(
                        isSelected ? theme.primary.opacity(0.2) :
                        isFixed ? theme.cardBackground :
                        val > 0 ? theme.primary.opacity(0.08) :
                        theme.primary.opacity(0.05)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: gridSize >= 5 ? 8 : 12)
                            .stroke(
                                isSelected ? theme.primary :
                                val > 0 && !isFixed ? Color.blue.opacity(0.3) :
                                theme.textSecondary.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )

                if val > 0 {
                    Text("\(val)")
                        .font(.system(size: cellFontSize, weight: isFixed ? .heavy : .bold, design: .rounded))
                        .foregroundColor(isFixed ? theme.textPrimary : .blue)
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .disabled(isFixed)
    }

    // MARK: - Sum Indicators

    private func rowSumIndicator(row: Int) -> some View {
        let rowSum = (0..<gridSize).reduce(0) { $0 + grid[row][$1] }
        let isRowComplete = (0..<gridSize).allSatisfy { grid[row][$0] > 0 }
        let isRowCorrect = isRowComplete && rowSum == targetSum
        return Text(rowSum > 0 ? "\(rowSum)" : "-")
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(isRowCorrect ? .green : isRowComplete ? .red : theme.textSecondary)
            .frame(width: 32)
    }

    private func colSumIndicator(col: Int) -> some View {
        let colSum = (0..<gridSize).reduce(0) { $0 + grid[$1][col] }
        let isColComplete = (0..<gridSize).allSatisfy { grid[$0][col] > 0 }
        let isCorrectCol = isColComplete && colSum == targetSum
        return Text(colSum > 0 ? "\(colSum)" : "-")
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundColor(isCorrectCol ? .green : isColComplete ? .red : theme.textSecondary)
            .frame(maxWidth: .infinity)
    }

    private func diagonalIndicator(isDiag1: Bool) -> some View {
        let diagSum: Int
        let isDiagComplete: Bool
        if isDiag1 {
            diagSum = (0..<gridSize).reduce(0) { $0 + grid[$1][$1] }
            isDiagComplete = (0..<gridSize).allSatisfy { grid[$0][$0] > 0 }
        } else {
            diagSum = (0..<gridSize).reduce(0) { $0 + grid[$1][gridSize - 1 - $1] }
            isDiagComplete = (0..<gridSize).allSatisfy { grid[$0][gridSize - 1 - $0] > 0 }
        }
        let isDiagCorrect = isDiagComplete && diagSum == targetSum

        return HStack(spacing: 4) {
            Image(systemName: isDiag1 ? "arrow.down.right" : "arrow.down.left")
                .font(.system(size: 10, weight: .bold))
            Text(diagSum > 0 ? "\(diagSum)" : "-")
                .font(.system(size: 13, weight: .bold, design: .rounded))
        }
        .foregroundColor(isDiagCorrect ? .green : isDiagComplete ? .red : theme.textSecondary)
    }

    // MARK: - Computed Properties

    private var allFilled: Bool {
        for r in 0..<gridSize { for c in 0..<gridSize { if grid[r][c] == 0 { return false } } }
        return true
    }

    private var canErase: Bool {
        selectedRow >= 0 && selectedCol >= 0 &&
        selectedRow < gridSize && selectedCol < gridSize &&
        !fixed[selectedRow][selectedCol] &&
        grid[selectedRow][selectedCol] > 0
    }

    // MARK: - Auto-Win Check

    private var isSolutionCorrect: Bool {
        guard allFilled else { return false }

        // Check rows
        for r in 0..<gridSize {
            if grid[r].reduce(0, +) != targetSum { return false }
        }
        // Check columns
        for c in 0..<gridSize {
            if (0..<gridSize).reduce(0, { $0 + grid[$1][c] }) != targetSum { return false }
        }
        // Check diagonals
        if (0..<gridSize).reduce(0, { $0 + grid[$1][$1] }) != targetSum { return false }
        if (0..<gridSize).reduce(0, { $0 + grid[$1][gridSize - 1 - $1] }) != targetSum { return false }

        return true
    }

    // MARK: - Number Management

    private func isNumberUsed(_ num: Int) -> Bool {
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                if r == selectedRow && c == selectedCol { continue }
                if grid[r][c] == num { return true }
            }
        }
        return false
    }

    private func placeNumber(_ num: Int) {
        guard selectedRow >= 0, selectedCol >= 0, !fixed[selectedRow][selectedCol] else { return }
        grid[selectedRow][selectedCol] = num
        HapticManager.shared.buttonTap()

        // Auto-check win after placing
        if isSolutionCorrect {
            isComplete = true
            score += level * 25
            StreakManager.shared.recordActivity()
            SoundManager.shared.playAchievement()
            HapticManager.shared.achievement()
        }
    }

    private func eraseSelected() {
        guard selectedRow >= 0, selectedCol >= 0, !fixed[selectedRow][selectedCol] else { return }
        grid[selectedRow][selectedCol] = 0
        HapticManager.shared.buttonTap()
    }

    private func clearAllUserNumbers() {
        for r in 0..<gridSize {
            for c in 0..<gridSize {
                if !fixed[r][c] {
                    grid[r][c] = 0
                }
            }
        }
        selectedRow = -1
        selectedCol = -1
        HapticManager.shared.buttonTap()
    }

    // MARK: - Puzzle Generation

    private func generatePuzzle() {
        isComplete = false; selectedRow = -1; selectedCol = -1
        gridSize = gridSizeForLevel

        solution = generateMagicSquare(size: gridSize, level: level)
        targetSum = solution[0].reduce(0, +)

        grid = solution
        fixed = Array(repeating: Array(repeating: true, count: gridSize), count: gridSize)

        // Hide cells based on level — more cells hidden as level increases
        let cellsToHide: Int
        if gridSize == 3 {
            // Levels 1-15: hide 3 to 7 cells (out of 9)
            cellsToHide = min(3 + (level - 1) / 3, 7)
        } else if gridSize == 4 {
            // Levels 16-35: hide 6 to 13 cells (out of 16)
            let progress = level - 15
            cellsToHide = min(6 + progress / 2, 13)
        } else {
            // Levels 36-50: hide 10 to 20 cells (out of 25)
            let progress = level - 35
            cellsToHide = min(10 + progress * 2 / 3, 20)
        }

        var hidden = 0

        // Step 1: Ensure every row has at least one hidden cell
        for r in 0..<gridSize {
            let c = Int.random(in: 0..<gridSize)
            if fixed[r][c] {
                grid[r][c] = 0
                fixed[r][c] = false
                hidden += 1
            }
        }

        // Step 2: Ensure every column has at least one hidden cell
        for c in 0..<gridSize {
            let hasHidden = (0..<gridSize).contains { !fixed[$0][c] }
            if !hasHidden {
                let r = Int.random(in: 0..<gridSize)
                if fixed[r][c] {
                    grid[r][c] = 0
                    fixed[r][c] = false
                    hidden += 1
                }
            }
        }

        // Step 3: Ensure both diagonals have at least one hidden cell
        let diag1Hidden = (0..<gridSize).contains { !fixed[$0][$0] }
        if !diag1Hidden {
            let i = Int.random(in: 0..<gridSize)
            if fixed[i][i] {
                grid[i][i] = 0
                fixed[i][i] = false
                hidden += 1
            }
        }
        let diag2Hidden = (0..<gridSize).contains { !fixed[$0][gridSize - 1 - $0] }
        if !diag2Hidden {
            let i = Int.random(in: 0..<gridSize)
            let j = gridSize - 1 - i
            if fixed[i][j] {
                grid[i][j] = 0
                fixed[i][j] = false
                hidden += 1
            }
        }

        // Step 4: Randomly hide remaining cells to reach target count
        var attempts = 0
        while hidden < cellsToHide && attempts < 200 {
            let r = Int.random(in: 0..<gridSize)
            let c = Int.random(in: 0..<gridSize)
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

    /// Generate a magic square of given size with level-based scaling
    private func generateMagicSquare(size: Int, level: Int) -> [[Int]] {
        switch size {
        case 3:
            return generate3x3(level: level)
        case 4:
            return generate4x4(level: level)
        case 5:
            return generate5x5(level: level)
        default:
            return generate3x3(level: level)
        }
    }

    private func generate3x3(level: Int) -> [[Int]] {
        // Classic 3x3 magic square with transformations
        let bases: [[[Int]]] = [
            [[2, 7, 6], [9, 5, 1], [4, 3, 8]],
            [[6, 1, 8], [7, 5, 3], [2, 9, 4]],
            [[8, 3, 4], [1, 5, 9], [6, 7, 2]],
            [[4, 9, 2], [3, 5, 7], [8, 1, 6]]
        ]
        let base = bases[Int.random(in: 0..<bases.count)]
        // Levels 1-3: simple (1-9), levels 4-8: small multiplier, levels 9-15: bigger numbers
        let factor: Int
        let offset: Int
        if level <= 3 {
            factor = 1; offset = 0
        } else if level <= 8 {
            factor = Int.random(in: 1...2); offset = Int.random(in: 0...5)
        } else {
            factor = Int.random(in: 2...4); offset = Int.random(in: 0...10)
        }
        return base.map { row in row.map { $0 * factor + offset } }
    }

    private func generate4x4(level: Int) -> [[Int]] {
        // 4x4 magic square (magic constant = 34 for 1-16)
        let bases: [[[Int]]] = [
            [[16, 2, 3, 13], [5, 11, 10, 8], [9, 7, 6, 12], [4, 14, 15, 1]],
            [[1, 15, 14, 4], [12, 6, 7, 9], [8, 10, 11, 5], [13, 3, 2, 16]]
        ]
        let base = bases[Int.random(in: 0..<bases.count)]
        // Levels 16-20: simple, 21-28: medium, 29-35: harder numbers
        let factor: Int
        let offset: Int
        if level <= 20 {
            factor = 1; offset = 0
        } else if level <= 28 {
            factor = Int.random(in: 1...2); offset = Int.random(in: 0...5)
        } else {
            factor = Int.random(in: 2...3); offset = Int.random(in: 0...8)
        }
        return base.map { row in row.map { $0 * factor + offset } }
    }

    private func generate5x5(level: Int) -> [[Int]] {
        // 5x5 magic square (magic constant = 65 for 1-25)
        let bases: [[[Int]]] = [
            [[17, 24, 1, 8, 15], [23, 5, 7, 14, 16], [4, 6, 13, 20, 22], [10, 12, 19, 21, 3], [11, 18, 25, 2, 9]],
            [[11, 18, 25, 2, 9], [10, 12, 19, 21, 3], [4, 6, 13, 20, 22], [23, 5, 7, 14, 16], [17, 24, 1, 8, 15]]
        ]
        let base = bases[Int.random(in: 0..<bases.count)]
        // Levels 36-40: simple, 41-45: medium, 46-50: hard numbers
        let factor: Int
        let offset: Int
        if level <= 40 {
            factor = 1; offset = 0
        } else if level <= 45 {
            factor = Int.random(in: 1...2); offset = Int.random(in: 0...5)
        } else {
            factor = Int.random(in: 2...3); offset = Int.random(in: 0...6)
        }
        return base.map { row in row.map { $0 * factor + offset } }
    }

    // MARK: - Overlays

    private func advanceLevel() {
        if level >= maxLevel {
            level = 1
            score = 0
        } else {
            level += 1
        }
        generatePuzzle()
    }

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: level >= maxLevel ? "trophy.fill" : "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(level >= maxLevel ? .yellow : .green)

                if level >= maxLevel {
                    Text("All 50 Levels Complete!")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Magic!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                }

                Text("Score: \(score)")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(.orange)

                Text("Level \(level)/\(maxLevel)")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(theme.textSecondary)

                if nextGridSize > gridSize && level < maxLevel {
                    Text("Next: \(nextGridSize)×\(nextGridSize) Grid!")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.orange.opacity(0.8))
                }

                VStack(spacing: 12) {
                    Button { advanceLevel() } label: {
                        HStack {
                            Image(systemName: level >= maxLevel ? "arrow.counterclockwise" : "arrow.right")
                            Text(level >= maxLevel ? "Play Again" : "Next Level")
                        }
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
