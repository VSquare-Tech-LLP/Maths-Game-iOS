import SwiftUI

struct SudokuGameView: View {
    @ObservedObject var settings = SettingsViewModel.shared
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = SudokuVM()
    @State private var isPaused = false

    private var theme: ColorTheme { settings.selectedTheme }

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
                            .background(theme.cardBackground)
                            .cornerRadius(10)
                    }

                    Spacer()

                    Text("Sudoku")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)

                    Spacer()

                    HStack(spacing: 8) {
                        Button {
                            isPaused = true
                            vm.pauseTimer()
                        } label: {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.textSecondary)
                                .frame(width: 36, height: 36)
                                .background(theme.cardBackground)
                                .cornerRadius(10)
                        }

                        Button {
                            vm.generatePuzzle()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.textSecondary)
                                .frame(width: 36, height: 36)
                                .background(theme.cardBackground)
                                .cornerRadius(10)
                        }
                    }
                }
                .padding(.horizontal)

                // Mistakes & Timer
                HStack(spacing: 24) {
                    Label("Mistakes: \(vm.mistakes)/3", systemImage: "xmark.circle")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(vm.mistakes >= 3 ? .red : theme.textSecondary)

                    Spacer()

                    // Hint button
                    Button {
                        vm.useHint()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 12, weight: .semibold))
                            Text("\(vm.hintsRemaining)")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(vm.hintsRemaining > 0 ? .yellow : theme.textSecondary.opacity(0.4))
                        .padding(.horizontal, 10).padding(.vertical, 5)
                        .background(theme.cardBackground).cornerRadius(8)
                    }
                    .disabled(vm.hintsRemaining <= 0)

                    Text(vm.formattedTime)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(theme.textSecondary)
                }
                .padding(.horizontal)

                // Sudoku Grid
                sudokuGrid
                    .padding(.horizontal, 4)

                // Number pad
                numberPad
                    .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 8)

            if vm.isComplete {
                completionOverlay
            }

            if vm.mistakes >= 3 {
                gameOverOverlay
            }

            if isPaused {
                MiniGamePauseOverlay(
                    theme: theme,
                    onResume: {
                        isPaused = false
                        vm.resumeTimer()
                    },
                    onRestart: {
                        isPaused = false
                        vm.generatePuzzle()
                    },
                    onGameSelection: {
                        isPaused = false
                        vm.pauseTimer()
                        dismiss()
                    },
                    onHome: {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            NotificationCenter.default.post(name: .miniGameGoHome, object: nil)
                        }
                    }
                )
            }
        }
        .onAppear { vm.generatePuzzle() }
    }

    private var sudokuGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<9, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { col in
                        let isSelected = vm.selectedRow == row && vm.selectedCol == col
                        let isFixed = vm.fixed[row][col]
                        let value = vm.board[row][col]
                        let isError = vm.errors[row][col]
                        let isHighlighted = vm.selectedRow == row || vm.selectedCol == col ||
                            (vm.selectedRow / 3 == row / 3 && vm.selectedCol / 3 == col / 3)

                        Text(value == 0 ? "" : "\(value)")
                            .font(.system(size: 18, weight: isFixed ? .bold : .medium, design: .rounded))
                            .foregroundColor(
                                isError ? .red :
                                isFixed ? theme.textPrimary :
                                Color.blue
                            )
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(
                                isSelected ? theme.primary.opacity(0.25) :
                                isHighlighted ? theme.primary.opacity(0.08) :
                                theme.cardBackground
                            )
                            .border(theme.textSecondary.opacity(0.15), width: 0.5)
                            .onTapGesture {
                                vm.selectedRow = row
                                vm.selectedCol = col
                            }
                    }
                }
                // Thicker lines for 3x3 boxes
                .overlay(alignment: .bottom) {
                    if row == 2 || row == 5 {
                        Rectangle().fill(theme.textPrimary.opacity(0.5)).frame(height: 2)
                    }
                }
            }
        }
        .overlay {
            // Vertical thick lines
            HStack(spacing: 0) {
                Spacer().frame(maxWidth: .infinity)
                Rectangle().fill(theme.textPrimary.opacity(0.5)).frame(width: 2)
                Spacer().frame(maxWidth: .infinity)
                Rectangle().fill(theme.textPrimary.opacity(0.5)).frame(width: 2)
                Spacer().frame(maxWidth: .infinity)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(theme.textPrimary.opacity(0.5), lineWidth: 2)
        )
    }

    private var numberPad: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                ForEach(1...5, id: \.self) { num in
                    numButton(num)
                }
            }
            HStack(spacing: 8) {
                ForEach(6...9, id: \.self) { num in
                    numButton(num)
                }
                // Erase button
                Button {
                    vm.eraseSelected()
                } label: {
                    Image(systemName: "delete.left.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(theme.cardBackground)
                        .cornerRadius(12)
                }
            }
        }
    }

    private func numButton(_ num: Int) -> some View {
        Button {
            vm.placeNumber(num)
        } label: {
            Text("\(num)")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(theme.textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(theme.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(theme.primary.opacity(0.2), lineWidth: 1)
                )
        }
    }

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                Text("Puzzle Complete!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                Text("Time: \(vm.formattedTime)")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(theme.textSecondary)

                VStack(spacing: 12) {
                    Button {
                        vm.generatePuzzle()
                    } label: {
                        HStack { Image(systemName: "arrow.counterclockwise"); Text("New Puzzle") }
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(14)
                    }
                    Button { dismiss() } label: {
                        Text("Back to Games")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(theme.textPrimary)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(theme.cardBackground).cornerRadius(14)
                    }
                }
            }
            .padding(28)
            .background(RoundedRectangle(cornerRadius: 24).fill(theme.background).shadow(color: .black.opacity(0.3), radius: 20, y: 10))
            .padding(.horizontal, 32)
        }
    }

    private var gameOverOverlay: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()
            VStack(spacing: 20) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.red)
                Text("Game Over")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                Text("Too many mistakes!")
                    .font(.system(size: 16, weight: .medium)).foregroundColor(theme.textSecondary)
                VStack(spacing: 12) {
                    Button { vm.generatePuzzle() } label: {
                        HStack { Image(systemName: "arrow.counterclockwise"); Text("Try Again") }
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing)).cornerRadius(14)
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
}

// MARK: - Sudoku ViewModel

@MainActor
final class SudokuVM: ObservableObject {
    @Published var board: [[Int]] = Array(repeating: Array(repeating: 0, count: 9), count: 9)
    @Published var solution: [[Int]] = Array(repeating: Array(repeating: 0, count: 9), count: 9)
    @Published var fixed: [[Bool]] = Array(repeating: Array(repeating: false, count: 9), count: 9)
    @Published var errors: [[Bool]] = Array(repeating: Array(repeating: false, count: 9), count: 9)
    @Published var selectedRow = -1
    @Published var selectedCol = -1
    @Published var mistakes = 0
    @Published var isComplete = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var hintsRemaining = 3

    private var timer: Timer?

    var formattedTime: String {
        let m = Int(elapsedTime) / 60
        let s = Int(elapsedTime) % 60
        return String(format: "%d:%02d", m, s)
    }

    func generatePuzzle() {
        mistakes = 0
        isComplete = false
        elapsedTime = 0
        selectedRow = -1
        selectedCol = -1
        hintsRemaining = 3
        errors = Array(repeating: Array(repeating: false, count: 9), count: 9)

        // Generate a solved board
        var grid = Array(repeating: Array(repeating: 0, count: 9), count: 9)
        _ = fillGrid(&grid)
        solution = grid

        // Remove cells to create puzzle (easy: ~36 clues)
        board = grid
        fixed = Array(repeating: Array(repeating: true, count: 9), count: 9)

        var cellsToRemove = 45
        while cellsToRemove > 0 {
            let r = Int.random(in: 0..<9)
            let c = Int.random(in: 0..<9)
            if board[r][c] != 0 {
                board[r][c] = 0
                fixed[r][c] = false
                cellsToRemove -= 1
            }
        }

        startTimer()
    }

    func placeNumber(_ num: Int) {
        guard selectedRow >= 0, selectedCol >= 0,
              !fixed[selectedRow][selectedCol],
              mistakes < 3, !isComplete else { return }

        if num == solution[selectedRow][selectedCol] {
            board[selectedRow][selectedCol] = num
            errors[selectedRow][selectedCol] = false
            SoundManager.shared.playCorrect()
            HapticManager.shared.correctAnswer()
            checkCompletion()
        } else {
            board[selectedRow][selectedCol] = num
            errors[selectedRow][selectedCol] = true
            mistakes += 1
            SoundManager.shared.playWrong()
            HapticManager.shared.wrongAnswer()
            if mistakes >= 3 {
                timer?.invalidate()
            }
        }
    }

    func eraseSelected() {
        guard selectedRow >= 0, selectedCol >= 0,
              !fixed[selectedRow][selectedCol] else { return }
        board[selectedRow][selectedCol] = 0
        errors[selectedRow][selectedCol] = false
    }

    func useHint() {
        guard hintsRemaining > 0 else { return }

        // Find an empty or incorrect non-fixed cell
        var candidates: [(Int, Int)] = []
        for r in 0..<9 {
            for c in 0..<9 {
                if !fixed[r][c] && board[r][c] != solution[r][c] {
                    candidates.append((r, c))
                }
            }
        }

        // Prefer selected cell if it's a valid candidate
        if selectedRow >= 0 && selectedCol >= 0 && !fixed[selectedRow][selectedCol] && board[selectedRow][selectedCol] != solution[selectedRow][selectedCol] {
            board[selectedRow][selectedCol] = solution[selectedRow][selectedCol]
            errors[selectedRow][selectedCol] = false
        } else if let pos = candidates.randomElement() {
            board[pos.0][pos.1] = solution[pos.0][pos.1]
            errors[pos.0][pos.1] = false
            selectedRow = pos.0
            selectedCol = pos.1
        } else {
            return // No cells to hint
        }

        hintsRemaining -= 1
        HapticManager.shared.buttonTap()
        checkCompletion()
    }

    func pauseTimer() {
        timer?.invalidate()
    }

    func resumeTimer() {
        startTimer()
    }

    private func checkCompletion() {
        for r in 0..<9 {
            for c in 0..<9 {
                if board[r][c] != solution[r][c] { return }
            }
        }
        isComplete = true
        timer?.invalidate()
        SoundManager.shared.playAchievement()
        HapticManager.shared.achievement()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.elapsedTime += 1 }
        }
    }

    // Backtracking Sudoku generator
    private func fillGrid(_ grid: inout [[Int]]) -> Bool {
        for r in 0..<9 {
            for c in 0..<9 {
                if grid[r][c] == 0 {
                    var nums = Array(1...9)
                    nums.shuffle()
                    for n in nums {
                        if isValid(grid, r, c, n) {
                            grid[r][c] = n
                            if fillGrid(&grid) { return true }
                            grid[r][c] = 0
                        }
                    }
                    return false
                }
            }
        }
        return true
    }

    private func isValid(_ grid: [[Int]], _ row: Int, _ col: Int, _ num: Int) -> Bool {
        for i in 0..<9 {
            if grid[row][i] == num || grid[i][col] == num { return false }
        }
        let br = (row / 3) * 3, bc = (col / 3) * 3
        for r in br..<br+3 {
            for c in bc..<bc+3 {
                if grid[r][c] == num { return false }
            }
        }
        return true
    }
}

#Preview { SudokuGameView() }
