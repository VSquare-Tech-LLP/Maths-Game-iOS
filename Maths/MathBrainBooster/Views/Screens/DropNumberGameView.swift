import SwiftUI

// MARK: - Drop & Merge Game (Drag same numbers to merge, reach 30!)

struct DropNumberGameView: View {
    @ObservedObject var settings = SettingsViewModel.shared
    @Environment(\.dismiss) private var dismiss

    private let cols = 6
    private let rows = 8
    private let maxNumber = 30

    @State private var grid: [[Int]] = []          // grid[row][col], 0 = empty
    @State private var score = 0
    @State private var bestScore: Int = UserDefaults.standard.integer(forKey: "dropNumberBest")
    @State private var highestNumber = 0
    @State private var isGameOver = false
    @State private var isWin = false
    @State private var isPaused = false
    @State private var moveCount = 0
    @State private var mergesUntilNewRow = 3  // new row every 3 merges

    // Drag state
    @State private var dragSource: (row: Int, col: Int)? = nil
    @State private var dragOffset: CGSize = .zero
    @State private var isDragging = false
    @State private var highlightTarget: (row: Int, col: Int)? = nil

    // Cell sizing
    @State private var cellSize: CGFloat = 55
    @State private var gridOrigin: CGPoint = .zero

    private var theme: ColorTheme { settings.selectedTheme }

    var body: some View {
        ZStack {
            // Wooden background
            LinearGradient(
                colors: [Color(red: 0.55, green: 0.35, blue: 0.22), Color(red: 0.65, green: 0.42, blue: 0.28)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 10) {
                topBar
                scoreSection

                // Game grid area
                gridArea

                Spacer(minLength: 4)
            }
            .padding(.top, 8)

            if isGameOver || isWin { gameOverOverlay }

            if isPaused {
                MiniGamePauseOverlay(
                    theme: theme,
                    onResume: { isPaused = false },
                    onRestart: { isPaused = false; resetGame() },
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
        .onAppear { resetGame() }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.15)).cornerRadius(10)
            }
            Spacer()
            Text("Drop & Merge")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Spacer()
            HStack(spacing: 8) {
                Button { isPaused = true } label: {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.15)).cornerRadius(10)
                }
                Button { resetGame() } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.15)).cornerRadius(10)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Score

    private var scoreSection: some View {
        HStack(spacing: 0) {
            VStack(spacing: 2) {
                Text("\(bestScore)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("BEST")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)

            // Score center
            VStack(spacing: 2) {
                Text("SCORE")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                Text("\(score)")
                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)

            VStack(spacing: 2) {
                Text("\(highestNumber)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.yellow)
                Text("MAX")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 8).padding(.horizontal, 12)
        .background(Color.white.opacity(0.12))
        .cornerRadius(14)
        .padding(.horizontal)
    }

    // MARK: - Grid Area

    private var gridArea: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 4
            let horizontalPad: CGFloat = 8
            let availableW = geo.size.width - horizontalPad * 2 - spacing * CGFloat(cols - 1)
            let computedCellW = floor(availableW / CGFloat(cols))
            let availableH = geo.size.height - 16
            let computedCellH = floor((availableH - spacing * CGFloat(rows - 1)) / CGFloat(rows))
            let cs = min(computedCellW, computedCellH, 65)

            let gridW = cs * CGFloat(cols) + spacing * CGFloat(cols - 1)
            let gridH = cs * CGFloat(rows) + spacing * CGFloat(rows - 1)
            let offsetX = (geo.size.width - gridW) / 2
            let offsetY = (geo.size.height - gridH) / 2

            ZStack(alignment: .topLeading) {
                // Container background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.22, green: 0.24, blue: 0.30))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.40, green: 0.30, blue: 0.20), lineWidth: 3)
                    )
                    .frame(width: gridW + 16, height: gridH + 16)

                // Grid cells
                ForEach(0..<rows, id: \.self) { row in
                    ForEach(0..<cols, id: \.self) { col in
                        let value = safeGridValue(row: row, col: col)
                        let isSource = dragSource?.row == row && dragSource?.col == col && isDragging
                        let isTarget = highlightTarget?.row == row && highlightTarget?.col == col

                        cellBlockView(value: value, size: cs, isSource: isSource, isTarget: isTarget)
                            .offset(
                                x: 8 + CGFloat(col) * (cs + spacing) + (isSource ? dragOffset.width : 0),
                                y: 8 + CGFloat(row) * (cs + spacing) + (isSource ? dragOffset.height : 0)
                            )
                            .zIndex(isSource ? 100 : 0)
                            .gesture(
                                value > 0 && !isGameOver && !isWin && !isPaused
                                ? DragGesture(minimumDistance: 5)
                                    .onChanged { gesture in
                                        if dragSource == nil {
                                            dragSource = (row, col)
                                            isDragging = true
                                        }
                                        dragOffset = gesture.translation

                                        // Find which cell we're hovering over
                                        let targetCol = col + Int(round(gesture.translation.width / (cs + spacing)))
                                        let targetRow = row + Int(round(gesture.translation.height / (cs + spacing)))

                                        if targetRow >= 0 && targetRow < rows && targetCol >= 0 && targetCol < cols
                                            && !(targetRow == row && targetCol == col)
                                            && safeGridValue(row: targetRow, col: targetCol) == value
                                            && canMergeTo(fromRow: row, fromCol: col, toRow: targetRow, toCol: targetCol) {
                                            highlightTarget = (targetRow, targetCol)
                                        } else {
                                            highlightTarget = nil
                                        }
                                    }
                                    .onEnded { gesture in
                                        handleDragEnd(fromRow: row, fromCol: col, gesture: gesture, cellSize: cs, spacing: spacing)
                                    }
                                : nil
                            )
                    }
                }
            }
            .frame(width: gridW + 16, height: gridH + 16)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .onAppear {
                cellSize = cs
            }
        }
        .padding(.horizontal, 8)
    }

    // MARK: - Cell Block View

    private func cellBlockView(value: Int, size: CGFloat, isSource: Bool, isTarget: Bool) -> some View {
        ZStack {
            if value > 0 {
                // Block body
                RoundedRectangle(cornerRadius: 10)
                    .fill(blockGradient(for: value))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isTarget ? Color.white : Color.white.opacity(0.3),
                                lineWidth: isTarget ? 3 : 1.5
                            )
                    )
                    .shadow(color: blockColor(for: value).opacity(0.4), radius: 3, y: 3)

                // Top-left shine
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.35), Color.clear],
                            startPoint: .topLeading, endPoint: .center
                        )
                    )
                    .padding(2)

                // Number
                Text("\(value)")
                    .font(.system(size: size * 0.42, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.35), radius: 1, x: 0, y: 1)

                // Glow effect for target
                if isTarget {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.2))
                }
            } else {
                // Empty cell
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            }
        }
        .frame(width: size, height: size)
        .opacity(isSource ? 0.8 : 1.0)
        .scaleEffect(isSource ? 1.1 : (isTarget ? 1.05 : 1.0))
        .animation(.easeOut(duration: 0.15), value: isTarget)
    }

    // MARK: - Block Colors

    private func blockColor(for value: Int) -> Color {
        switch value {
        case 1:  return Color(red: 0.85, green: 0.55, blue: 0.25) // orange
        case 2:  return Color(red: 0.70, green: 0.82, blue: 0.35) // lime
        case 3:  return Color(red: 0.55, green: 0.75, blue: 0.90) // sky blue
        case 4:  return Color(red: 0.85, green: 0.45, blue: 0.55) // pink
        case 5:  return Color(red: 0.85, green: 0.78, blue: 0.35) // gold
        case 6:  return Color(red: 0.45, green: 0.78, blue: 0.55) // green
        case 7:  return Color(red: 0.60, green: 0.50, blue: 0.82) // purple
        case 8:  return Color(red: 0.90, green: 0.48, blue: 0.40) // red
        case 9:  return Color(red: 0.40, green: 0.68, blue: 0.85) // teal
        case 10: return Color(red: 0.92, green: 0.62, blue: 0.28) // bright orange
        case 11: return Color(red: 0.55, green: 0.40, blue: 0.72) // deep purple
        case 12: return Color(red: 0.30, green: 0.72, blue: 0.68) // cyan
        default:
            let hue = Double((value * 41) % 360) / 360.0
            return Color(hue: hue, saturation: 0.65, brightness: 0.82)
        }
    }

    private func blockGradient(for value: Int) -> LinearGradient {
        let base = blockColor(for: value)
        return LinearGradient(
            colors: [base.opacity(0.9), base, base.opacity(0.75)],
            startPoint: .top, endPoint: .bottom
        )
    }

    // MARK: - Grid Helpers

    private func safeGridValue(row: Int, col: Int) -> Int {
        guard row >= 0, row < grid.count, col >= 0, col < grid[row].count else { return 0 }
        return grid[row][col]
    }

    /// Check if source can reach destination through a clear path of empty cells.
    /// When we pick up the source block, that cell becomes empty.
    /// We use BFS to flood-fill through empty cells and check if
    /// the destination is adjacent to any reachable empty cell.
    private func canMergeTo(fromRow: Int, fromCol: Int, toRow: Int, toCol: Int) -> Bool {
        // Same cell? No
        if fromRow == toRow && fromCol == toCol { return false }
        // Target must have same value
        let val = safeGridValue(row: fromRow, col: fromCol)
        let targetVal = safeGridValue(row: toRow, col: toCol)
        if val == 0 || targetVal == 0 || val != targetVal { return false }

        // Directly adjacent? Always valid (no gap needed)
        let dr = abs(fromRow - toRow)
        let dc = abs(fromCol - toCol)
        if dr + dc == 1 { return true }

        // BFS: find path through empty cells from source to a cell adjacent to destination
        // Source cell is treated as empty (we picked it up)
        var visited = Array(repeating: Array(repeating: false, count: cols), count: rows)
        var queue: [(Int, Int)] = [(fromRow, fromCol)]
        visited[fromRow][fromCol] = true

        let directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]

        while !queue.isEmpty {
            let (r, c) = queue.removeFirst()

            // Check if this cell is adjacent to the destination
            for (dr, dc) in directions {
                let nr = r + dr
                let nc = c + dc
                if nr == toRow && nc == toCol {
                    return true  // We can reach destination from here
                }
            }

            // Expand to neighboring empty cells
            for (dr, dc) in directions {
                let nr = r + dr
                let nc = c + dc
                guard nr >= 0, nr < rows, nc >= 0, nc < cols,
                      !visited[nr][nc] else { continue }

                // Cell must be empty (0) to walk through.
                // Source cell is already treated as empty since we started there.
                if grid[nr][nc] == 0 {
                    visited[nr][nc] = true
                    queue.append((nr, nc))
                }
            }
        }

        return false  // No clear path found
    }

    // MARK: - Drag & Drop Logic

    private func handleDragEnd(fromRow: Int, fromCol: Int, gesture: DragGesture.Value, cellSize cs: CGFloat, spacing: CGFloat) {
        let targetCol = fromCol + Int(round(gesture.translation.width / (cs + spacing)))
        let targetRow = fromRow + Int(round(gesture.translation.height / (cs + spacing)))

        // Reset drag visuals
        withAnimation(.easeOut(duration: 0.15)) {
            dragOffset = .zero
            isDragging = false
        }

        let source = dragSource
        dragSource = nil
        highlightTarget = nil

        guard let src = source else { return }

        // Validate merge
        guard targetRow >= 0, targetRow < rows, targetCol >= 0, targetCol < cols,
              !(targetRow == src.row && targetCol == src.col),
              canMergeTo(fromRow: src.row, fromCol: src.col, toRow: targetRow, toCol: targetCol) else {
            return
        }

        // Perform merge
        let oldVal = grid[src.row][src.col]
        let newVal = oldVal + 1

        grid[src.row][src.col] = 0       // remove source
        grid[targetRow][targetCol] = newVal  // upgrade target

        score += newVal * 10
        moveCount += 1

        if newVal > highestNumber {
            highestNumber = newVal
        }

        SoundManager.shared.playCorrect()
        HapticManager.shared.correctAnswer()

        // Apply gravity
        applyGravity()

        // Check for chain merges (auto-merge adjacent same numbers after gravity)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            checkChainMerges()
        }

        // Check win
        if highestNumber >= maxNumber {
            win()
            return
        }

        // New row every N merges
        mergesUntilNewRow -= 1
        if mergesUntilNewRow <= 0 {
            mergesUntilNewRow = 3
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                addNewRow()
            }
        }
    }

    // MARK: - Chain Merges (auto merge adjacent same numbers after gravity)

    private func checkChainMerges() {
        // Check all cells for adjacent pairs that auto-merged after gravity
        // This doesn't auto-merge, just applies gravity again to settle
        applyGravity()

        // Check game over
        if isTopRowFilled() {
            gameOver()
        }
    }

    // MARK: - Gravity

    private func applyGravity() {
        for col in 0..<cols {
            var values: [Int] = []
            for row in stride(from: rows - 1, through: 0, by: -1) {
                if grid[row][col] != 0 {
                    values.append(grid[row][col])
                }
            }
            for row in stride(from: rows - 1, through: 0, by: -1) {
                let idx = rows - 1 - row
                grid[row][col] = idx < values.count ? values[idx] : 0
            }
        }
    }

    // MARK: - New Row

    private func addNewRow() {
        guard !isGameOver, !isWin else { return }

        // Check if top row has any blocks (would overflow)
        for col in 0..<cols {
            if grid[0][col] != 0 {
                gameOver()
                return
            }
        }

        // Shift everything up by 1 row
        for row in 0..<(rows - 1) {
            for col in 0..<cols {
                grid[row][col] = grid[row + 1][col]
            }
        }

        // Fill bottom row with random numbers
        for col in 0..<cols {
            grid[rows - 1][col] = randomStartNumber()
        }

        SoundManager.shared.playButtonTap()
        HapticManager.shared.buttonTap()

        // Check if top row filled after push
        if isTopRowFilled() {
            gameOver()
        }
    }

    private func isTopRowFilled() -> Bool {
        for col in 0..<cols {
            if grid[0][col] != 0 { return true }
        }
        return false
    }

    // MARK: - Game Setup

    private func randomStartNumber() -> Int {
        let choices = [1, 1, 1, 2, 2, 3, 3, 4, 5]
        return choices.randomElement()!
    }

    private func resetGame() {
        // Init empty grid
        grid = Array(repeating: Array(repeating: 0, count: cols), count: rows)

        // Fill bottom 2 rows with random numbers
        for row in (rows - 2)..<rows {
            for col in 0..<cols {
                grid[row][col] = randomStartNumber()
            }
        }

        score = 0
        highestNumber = 5
        isGameOver = false
        isWin = false
        moveCount = 0
        mergesUntilNewRow = 3
        dragSource = nil
        dragOffset = .zero
        isDragging = false
        highlightTarget = nil

        updateHighest()
    }

    private func updateHighest() {
        for row in 0..<rows {
            for col in 0..<cols {
                if grid[row][col] > highestNumber {
                    highestNumber = grid[row][col]
                }
            }
        }
    }

    private func gameOver() {
        isGameOver = true
        if score > bestScore {
            bestScore = score
            UserDefaults.standard.set(bestScore, forKey: "dropNumberBest")
        }
        StreakManager.shared.recordActivity()
        SoundManager.shared.playWrong()
        HapticManager.shared.wrongAnswer()
    }

    private func win() {
        isWin = true
        if score > bestScore {
            bestScore = score
            UserDefaults.standard.set(bestScore, forKey: "dropNumberBest")
        }
        StreakManager.shared.recordActivity()
        SoundManager.shared.playAchievement()
        HapticManager.shared.achievement()
    }

    // MARK: - Game Over / Win Overlay

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.6).ignoresSafeArea()

            VStack(spacing: 20) {
                if isWin {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.yellow)
                    Text("You Win!")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Reached \(maxNumber)!")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                } else {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 56))
                        .foregroundColor(.red.opacity(0.8))
                    Text("Game Over")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("\(score)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                        Text("Score")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    VStack(spacing: 4) {
                        Text("\(highestNumber)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.purple)
                        Text("Highest")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    VStack(spacing: 4) {
                        Text("\(bestScore)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                        Text("Best")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                if score >= bestScore && score > 0 {
                    Text("New Best!")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.yellow)
                }

                VStack(spacing: 12) {
                    Button { resetGame() } label: {
                        HStack { Image(systemName: "arrow.counterclockwise"); Text("Play Again") }
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: isWin ? [.yellow, .orange] : [.blue, .cyan],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .cornerRadius(14)
                    }
                    Button { dismiss() } label: {
                        Text("Back to Games")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(Color.white.opacity(0.12)).cornerRadius(14)
                    }
                }
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.20, green: 0.22, blue: 0.28))
                    .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
            )
            .padding(.horizontal, 32)
        }
    }
}

#Preview { DropNumberGameView() }
