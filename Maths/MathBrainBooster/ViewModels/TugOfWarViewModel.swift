import SwiftUI
import Combine

@MainActor
final class TugOfWarViewModel: ObservableObject {

    // MARK: - Published state

    @Published var gamePhase: GamePhase = .idle
    @Published var countdownValue: Int = 3

    // Player
    @Published var playerQuestion: Question?
    @Published var playerScore: Int = 0
    @Published var playerCorrect: Int = 0
    @Published var playerWrong: Int = 0
    @Published var playerStreak: Int = 0
    @Published var playerBestStreak: Int = 0
    @Published var playerMultiplier: Int = 1
    @Published var selectedAnswer: Int?
    @Published var showAnswerFeedback = false
    @Published var lastAnswerCorrect: Bool?

    // Opponent (AI)
    @Published var opponentName: String = ""
    @Published var opponentQuestion: Question?
    @Published var opponentScore: Int = 0
    @Published var opponentCorrect: Int = 0
    @Published var opponentShowFeedback = false
    @Published var opponentLastCorrect: Bool?

    // Tug of War
    @Published var ropePosition: CGFloat = 0          // -1.0 (player wins) to +1.0 (AI wins)
    @Published var tugSteps: Int = 0                   // net: negative = player leading
    @Published var maxSteps: Int = 7                   // steps to win

    // Timer
    @Published var timeRemaining: TimeInterval = 0
    @Published var totalTime: TimeInterval = 0
    @Published var questionNumber: Int = 0
    @Published var totalQuestions: Int = 0

    // Result
    @Published var playerWon: Bool?
    @Published var isDraw = false

    // Config
    var gameMode: GameMode = .addition
    var difficulty: Difficulty = .easy

    private var timer: Timer?
    private var opponentTimer: Timer?

    private let soundManager = SoundManager.shared
    private let hapticManager = HapticManager.shared

    private static let opponentNames = [
        "Alex", "Mia", "Arjun", "Zara", "Sam",
        "Luna", "Kai", "Nora", "Omar", "Yuki",
        "Leo", "Ivy", "Ravi", "Emma", "Jay"
    ]

    // MARK: - Computed

    var timerProgress: CGFloat {
        guard totalTime > 0 else { return 1 }
        return CGFloat(timeRemaining / totalTime)
    }

    var timerColor: Color {
        let p = timerProgress
        if p > 0.5 { return .green }
        if p > 0.25 { return .yellow }
        return .red
    }

    var ropeNormalized: CGFloat {
        guard maxSteps > 0 else { return 0 }
        return CGFloat(tugSteps) / CGFloat(maxSteps)
    }

    var playerStats: GameStats {
        var s = GameStats()
        s.correctAnswers = playerCorrect
        s.wrongAnswers = playerWrong
        s.bestStreak = playerBestStreak
        s.totalScore = playerScore
        s.multiplier = playerMultiplier
        s.currentStreak = playerStreak
        s.questionsAnswered = playerCorrect + playerWrong
        return s
    }

    // AI speed range (seconds) per difficulty
    private var opponentSpeedRange: ClosedRange<Double> {
        switch difficulty {
        case .easy:   return 3.5...6.0
        case .medium: return 2.5...4.5
        case .hard:   return 1.8...3.2
        case .expert: return 1.2...2.5
        }
    }

    // AI accuracy per difficulty
    private var opponentAccuracy: Double {
        switch difficulty {
        case .easy:   return 0.55
        case .medium: return 0.65
        case .hard:   return 0.78
        case .expert: return 0.88
        }
    }

    // MARK: - Game lifecycle

    func startGame(mode: GameMode, difficulty: Difficulty) {
        self.gameMode = mode
        self.difficulty = difficulty
        self.totalQuestions = difficulty.questionsPerRound
        self.questionNumber = 0
        self.opponentName = Self.opponentNames.randomElement()!

        // Reset
        playerScore = 0; playerCorrect = 0; playerWrong = 0
        playerStreak = 0; playerBestStreak = 0; playerMultiplier = 1
        opponentScore = 0; opponentCorrect = 0
        tugSteps = 0; ropePosition = 0
        playerWon = nil; isDraw = false
        selectedAnswer = nil; showAnswerFeedback = false
        opponentShowFeedback = false

        gamePhase = .countdown
        countdownValue = 3
        startCountdown()
    }

    private func startCountdown() {
        soundManager.playCountdown()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.countdownValue -= 1
                if self.countdownValue > 0 {
                    self.soundManager.playCountdown()
                } else {
                    self.timer?.invalidate()
                    self.gamePhase = .playing
                    self.nextPlayerQuestion()
                    self.nextOpponentQuestion()
                    self.scheduleOpponentAnswer()
                }
            }
        }
    }

    // MARK: - Player questions

    private func nextPlayerQuestion() {
        guard !isGameOver() else { endGame(); return }
        questionNumber += 1
        selectedAnswer = nil
        showAnswerFeedback = false
        lastAnswerCorrect = nil
        playerQuestion = Question.generate(mode: gameMode, difficulty: difficulty)
        totalTime = difficulty.timePerQuestion
        timeRemaining = totalTime
        startQuestionTimer()
    }

    private func startQuestionTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.timeRemaining -= 0.05
                if self.timeRemaining <= 0 {
                    self.timeRemaining = 0
                    self.handlePlayerTimeout()
                }
            }
        }
    }

    func selectAnswer(_ answer: Int) {
        guard gamePhase == .playing, !showAnswerFeedback else { return }
        timer?.invalidate()
        selectedAnswer = answer

        let isCorrect = answer == playerQuestion?.correctAnswer
        lastAnswerCorrect = isCorrect
        showAnswerFeedback = true

        if isCorrect {
            playerCorrect += 1
            playerStreak += 1
            playerBestStreak = max(playerBestStreak, playerStreak)
            updatePlayerMultiplier()
            playerScore += difficulty.pointsPerCorrect * playerMultiplier
            tugSteps -= 1
            soundManager.playCorrect()
            hapticManager.correctAnswer()
            if playerStreak > 0 && playerStreak % 5 == 0 {
                soundManager.playStreakMilestone()
                hapticManager.streakMilestone()
            }
        } else {
            playerWrong += 1
            playerStreak = 0
            playerMultiplier = 1
            soundManager.playWrong()
            hapticManager.wrongAnswer()

            if let q = playerQuestion {
                MistakesManager.shared.addMistake(
                    questionText: q.text,
                    correctAnswer: q.correctAnswer,
                    userAnswer: answer,
                    mode: gameMode,
                    difficulty: difficulty
                )
            }
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            ropePosition = ropeNormalized
        }

        if isGameOver() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.endGame()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.nextPlayerQuestion()
            }
        }
    }

    private func handlePlayerTimeout() {
        playerWrong += 1
        playerStreak = 0
        playerMultiplier = 1
        lastAnswerCorrect = false
        showAnswerFeedback = true
        soundManager.playWrong()
        hapticManager.wrongAnswer()

        if let q = playerQuestion {
            MistakesManager.shared.addMistake(
                questionText: q.text,
                correctAnswer: q.correctAnswer,
                userAnswer: nil,
                mode: gameMode,
                difficulty: difficulty
            )
        }

        if isGameOver() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.endGame()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.nextPlayerQuestion()
            }
        }
    }

    private func updatePlayerMultiplier() {
        if playerStreak >= 10 { playerMultiplier = 3 }
        else if playerStreak >= 5 { playerMultiplier = 2 }
        else { playerMultiplier = 1 }
    }

    // MARK: - Opponent AI

    private func nextOpponentQuestion() {
        opponentShowFeedback = false
        opponentLastCorrect = nil
        opponentQuestion = Question.generate(mode: gameMode, difficulty: difficulty)
    }

    private func scheduleOpponentAnswer() {
        opponentTimer?.invalidate()
        let range = opponentSpeedRange
        let delay = Double.random(in: range)
        opponentTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.gamePhase == .playing else { return }
                self.handleOpponentAnswer()
            }
        }
    }

    private func handleOpponentAnswer() {
        guard gamePhase == .playing else { return }

        let gotCorrect = Double.random(in: 0...1) < opponentAccuracy
        opponentLastCorrect = gotCorrect
        opponentShowFeedback = true

        if gotCorrect {
            opponentCorrect += 1
            opponentScore += difficulty.pointsPerCorrect
            tugSteps += 1
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            ropePosition = ropeNormalized
        }

        if isGameOver() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.endGame()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                guard let self else { return }
                self.nextOpponentQuestion()
                self.scheduleOpponentAnswer()
            }
        }
    }

    // MARK: - Game end

    private func isGameOver() -> Bool {
        if abs(tugSteps) >= maxSteps { return true }
        let playerDone = (playerCorrect + playerWrong) >= totalQuestions
        let opponentDone = opponentCorrect >= totalQuestions
        if playerDone && opponentDone { return true }
        return false
    }

    private func endGame() {
        guard gamePhase == .playing else { return }
        timer?.invalidate()
        opponentTimer?.invalidate()

        if tugSteps < 0 {
            playerWon = true
        } else if tugSteps > 0 {
            playerWon = false
        } else {
            isDraw = true
            playerWon = playerScore > opponentScore
        }

        gamePhase = .gameOver

        if playerWon == true {
            soundManager.playAchievement()
            hapticManager.achievement()
        } else {
            soundManager.playGameOver()
            hapticManager.gameOver()
        }

        let result = GameResult(
            mode: gameMode,
            difficulty: difficulty,
            score: playerScore,
            correctAnswers: playerCorrect,
            totalQuestions: playerCorrect + playerWrong,
            bestStreak: playerBestStreak,
            accuracy: playerStats.accuracy
        )
        StatsViewModel.shared.addResult(result)
        AchievementManager.shared.checkAchievements(result: result, stats: playerStats)
        GameCenterManager.shared.submitScore(playerScore, mode: gameMode, difficulty: difficulty)
    }

    func resetGame() {
        timer?.invalidate()
        opponentTimer?.invalidate()
        gamePhase = .idle
    }

    func pauseGame() {
        guard gamePhase == .playing else { return }
        timer?.invalidate()
        opponentTimer?.invalidate()
        gamePhase = .paused
    }

    func resumeGame() {
        guard gamePhase == .paused else { return }
        gamePhase = .playing
        startQuestionTimer()
        scheduleOpponentAnswer()
    }
}
