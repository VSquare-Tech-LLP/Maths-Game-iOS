import SwiftUI
import Combine

@MainActor
final class AdvancedMathViewModel: ObservableObject {
    @Published var gamePhase: GamePhase = .idle
    @Published var currentQuestion: AdvancedMathQuestion?
    @Published var stats = GameStats()
    @Published var timeRemaining: TimeInterval = 0
    @Published var totalTime: TimeInterval = 0
    @Published var questionNumber: Int = 0
    @Published var totalQuestions: Int = 0
    @Published var countdownValue: Int = 3
    @Published var lastAnswerCorrect: Bool?
    @Published var showAnswerFeedback = false
    @Published var selectedAnswer: Int?

    var mathType: AdvancedMathType = .integers
    var difficulty: Difficulty = .easy

    private var timer: Timer?
    private let soundManager = SoundManager.shared
    private let hapticManager = HapticManager.shared
    private let achievementManager = AchievementManager.shared
    private let analytics = AnalyticsManager.shared
    private let interstitialManager = InterstitialAdManager.shared

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

    // MARK: - Game Lifecycle

    func startGame(type: AdvancedMathType, difficulty: Difficulty) {
        self.mathType = type
        self.difficulty = difficulty
        self.stats = GameStats()
        self.totalQuestions = difficulty.questionsPerRound
        self.questionNumber = 0
        self.gamePhase = .countdown
        self.countdownValue = 3
        self.selectedAnswer = nil
        self.showAnswerFeedback = false
        self.lastAnswerCorrect = nil

        analytics.logGameStarted(mode: .mixed, difficulty: difficulty)
        startCountdown()
    }

    private func startCountdown() {
        countdownValue = 3
        soundManager.playCountdown()

        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.countdownValue -= 1
                if self.countdownValue > 0 {
                    self.soundManager.playCountdown()
                } else {
                    self.timer?.invalidate()
                    self.gamePhase = .playing
                    self.nextQuestion()
                }
            }
        }
    }

    func nextQuestion() {
        guard gamePhase == .playing else { return }
        guard questionNumber < totalQuestions else {
            endGame()
            return
        }

        questionNumber += 1
        lastAnswerCorrect = nil
        showAnswerFeedback = false
        selectedAnswer = nil
        currentQuestion = AdvancedMathQuestion.generate(type: mathType, difficulty: difficulty)

        totalTime = difficulty.timePerQuestion
        timeRemaining = totalTime
        startTimer()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.timeRemaining -= 0.05
                if self.timeRemaining <= 0 {
                    self.timeRemaining = 0
                    self.handleTimeout()
                }
            }
        }
    }

    func selectAnswer(_ answer: Int) {
        guard gamePhase == .playing, !showAnswerFeedback else { return }
        timer?.invalidate()
        selectedAnswer = answer

        let isCorrect = answer == currentQuestion?.correctAnswer
        lastAnswerCorrect = isCorrect
        showAnswerFeedback = true
        stats.questionsAnswered += 1

        if isCorrect {
            stats.correctAnswers += 1
            stats.currentStreak += 1
            stats.bestStreak = max(stats.bestStreak, stats.currentStreak)
            updateMultiplier()
            stats.totalScore += difficulty.pointsPerCorrect * stats.multiplier
            soundManager.playCorrect()
            hapticManager.correctAnswer()

            if stats.currentStreak > 0 && stats.currentStreak % 5 == 0 {
                soundManager.playStreakMilestone()
                hapticManager.streakMilestone()
            }
        } else {
            stats.wrongAnswers += 1
            stats.currentStreak = 0
            stats.multiplier = 1
            soundManager.playWrong()
            hapticManager.wrongAnswer()

            if let q = currentQuestion {
                MistakesManager.shared.addMistake(
                    questionText: q.text,
                    correctAnswer: q.correctAnswer,
                    userAnswer: answer,
                    mode: .mixed,
                    difficulty: difficulty
                )
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.nextQuestion()
        }
    }

    private func handleTimeout() {
        timer?.invalidate()
        guard gamePhase == .playing, !showAnswerFeedback else { return }

        stats.questionsAnswered += 1
        stats.wrongAnswers += 1
        stats.currentStreak = 0
        stats.multiplier = 1
        lastAnswerCorrect = false
        showAnswerFeedback = true
        soundManager.playWrong()
        hapticManager.wrongAnswer()

        if let q = currentQuestion {
            MistakesManager.shared.addMistake(
                questionText: q.text,
                correctAnswer: q.correctAnswer,
                userAnswer: nil,
                mode: .mixed,
                difficulty: difficulty
            )
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            self?.nextQuestion()
        }
    }

    private func updateMultiplier() {
        if stats.currentStreak >= 10 { stats.multiplier = 3 }
        else if stats.currentStreak >= 5 { stats.multiplier = 2 }
        else { stats.multiplier = 1 }
    }

    private func endGame() {
        timer?.invalidate()
        gamePhase = .gameOver
        soundManager.playGameOver()
        hapticManager.gameOver()

        let result = GameResult(
            mode: .mixed,
            difficulty: difficulty,
            score: stats.totalScore,
            correctAnswers: stats.correctAnswers,
            totalQuestions: stats.questionsAnswered,
            bestStreak: stats.bestStreak,
            accuracy: stats.accuracy
        )

        StatsViewModel.shared.addResult(result)
        achievementManager.checkAchievements(result: result, stats: stats)
        GameCenterManager.shared.submitScore(stats.totalScore, mode: .mixed, difficulty: difficulty)
        interstitialManager.gameCompleted()
    }

    func resetGame() {
        timer?.invalidate()
        gamePhase = .idle
        stats = GameStats()
        currentQuestion = nil
        questionNumber = 0
    }

    func pauseGame() {
        guard gamePhase == .playing else { return }
        timer?.invalidate()
        gamePhase = .paused
    }

    func resumeGame() {
        guard gamePhase == .paused else { return }
        gamePhase = .playing
        startTimer()
    }
}
