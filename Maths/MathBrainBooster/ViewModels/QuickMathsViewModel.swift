import SwiftUI
import Combine

@MainActor
final class QuickMathsViewModel: ObservableObject {

    // MARK: - Configuration

    enum TimerMode: Equatable {
        case oneMinute
        case fiveMinutes
        case fifteenMinutes
        case twentyMinutes
        case custom(minutes: Int)
        case unlimited

        var seconds: TimeInterval? {
            switch self {
            case .oneMinute:       return 60
            case .fiveMinutes:     return 300
            case .fifteenMinutes:  return 900
            case .twentyMinutes:   return 1200
            case .custom(let m):   return TimeInterval(m * 60)
            case .unlimited:       return nil
            }
        }

        var label: String {
            switch self {
            case .oneMinute:       return "1 Min"
            case .fiveMinutes:     return "5 Min"
            case .fifteenMinutes:  return "15 Min"
            case .twentyMinutes:   return "20 Min"
            case .custom(let m):   return "\(m) Min"
            case .unlimited:       return "Unlimited"
            }
        }
    }

    enum QuestionLimit: Equatable {
        case fixed(count: Int)
        case unlimited

        var label: String {
            switch self {
            case .fixed(let c): return "\(c) Questions"
            case .unlimited:    return "Unlimited"
            }
        }
    }

    // MARK: - Published state

    @Published var gamePhase: GamePhase = .idle
    @Published var countdownValue: Int = 3

    @Published var currentQuestion: Question?
    @Published var selectedAnswer: Int?
    @Published var showAnswerFeedback = false
    @Published var lastAnswerCorrect: Bool?

    @Published var stats = GameStats()

    @Published var timeRemaining: TimeInterval = 0
    @Published var totalTime: TimeInterval = 0
    @Published var questionNumber: Int = 0

    // Config
    var gameMode: GameMode = .mixed
    var difficulty: Difficulty = .medium
    var timerMode: TimerMode = .fiveMinutes
    var questionLimit: QuestionLimit = .unlimited

    private var timer: Timer?
    private let soundManager = SoundManager.shared
    private let hapticManager = HapticManager.shared
    private let analytics = AnalyticsManager.shared
    private let interstitialManager = InterstitialAdManager.shared

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

    var isTimerBased: Bool {
        timerMode.seconds != nil
    }

    var hasQuestionLimit: Bool {
        if case .fixed = questionLimit { return true }
        return false
    }

    var maxQuestions: Int? {
        if case .fixed(let c) = questionLimit { return c }
        return nil
    }

    var formattedTimeRemaining: String {
        let mins = Int(timeRemaining) / 60
        let secs = Int(timeRemaining) % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var questionsPerMinute: Double {
        guard let totalSec = timerMode.seconds else { return 0 }
        let elapsed = totalSec - timeRemaining
        guard elapsed > 0 else { return 0 }
        return Double(stats.questionsAnswered) / (elapsed / 60.0)
    }

    // MARK: - Game lifecycle

    func startGame(mode: GameMode, difficulty: Difficulty, timerMode: TimerMode, questionLimit: QuestionLimit) {
        self.gameMode = mode
        self.difficulty = difficulty
        self.timerMode = timerMode
        self.questionLimit = questionLimit
        self.questionNumber = 0
        self.stats = GameStats()
        self.selectedAnswer = nil
        self.showAnswerFeedback = false
        self.lastAnswerCorrect = nil

        if let secs = timerMode.seconds {
            totalTime = secs
            timeRemaining = secs
        } else {
            totalTime = 0
            timeRemaining = 0
        }

        gamePhase = .countdown
        countdownValue = 3
        analytics.logQuickMathsStarted(mode: mode, difficulty: difficulty,
                                       timerMode: timerMode.label, questionLimit: questionLimit.label)
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
                    self.nextQuestion()
                    if self.isTimerBased {
                        self.startGlobalTimer()
                    }
                }
            }
        }
    }

    // MARK: - Questions

    private func nextQuestion() {
        guard gamePhase == .playing else { return }
        guard !isGameFinished() else { endGame(); return }

        questionNumber += 1
        selectedAnswer = nil
        showAnswerFeedback = false
        lastAnswerCorrect = nil
        currentQuestion = Question.generate(mode: gameMode, difficulty: difficulty)
    }

    func selectAnswer(_ answer: Int) {
        guard gamePhase == .playing, !showAnswerFeedback else { return }
        selectedAnswer = answer

        let isCorrect = answer == currentQuestion?.correctAnswer
        lastAnswerCorrect = isCorrect
        showAnswerFeedback = true
        stats.questionsAnswered += 1
        analytics.logAnswerSubmitted(isCorrect: isCorrect, currentStreak: stats.currentStreak, mode: gameMode)

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
                    mode: gameMode,
                    difficulty: difficulty
                )
            }
        }

        if isGameFinished() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.endGame()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.nextQuestion()
            }
        }
    }

    // MARK: - Timer

    private func startGlobalTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.timeRemaining -= 0.05
                if self.timeRemaining <= 0 {
                    self.timeRemaining = 0
                    self.timer?.invalidate()
                    self.endGame()
                }
            }
        }
    }

    // MARK: - Game state

    private func isGameFinished() -> Bool {
        if isTimerBased && timeRemaining <= 0 { return true }
        if let max = maxQuestions, stats.questionsAnswered >= max { return true }
        return false
    }

    private func endGame() {
        guard gamePhase == .playing else { return }
        timer?.invalidate()
        gamePhase = .gameOver

        soundManager.playAchievement()
        hapticManager.achievement()

        let result = GameResult(
            mode: gameMode,
            difficulty: difficulty,
            score: stats.totalScore,
            correctAnswers: stats.correctAnswers,
            totalQuestions: stats.questionsAnswered,
            bestStreak: stats.bestStreak,
            accuracy: stats.accuracy
        )
        StatsViewModel.shared.addResult(result)
        AchievementManager.shared.checkAchievements(result: result, stats: stats)
        GameCenterManager.shared.submitScore(stats.totalScore, mode: gameMode, difficulty: difficulty)
        analytics.logQuickMathsCompleted(mode: gameMode, difficulty: difficulty, score: stats.totalScore,
                                         accuracy: stats.accuracy, bestStreak: stats.bestStreak,
                                         totalQuestions: stats.questionsAnswered)

        // Show interstitial ad every few games
        interstitialManager.gameCompleted()
    }

    private func updateMultiplier() {
        if stats.currentStreak >= 10 { stats.multiplier = 3 }
        else if stats.currentStreak >= 5 { stats.multiplier = 2 }
        else { stats.multiplier = 1 }
    }

    // MARK: - Pause / Resume / Reset

    func pauseGame() {
        guard gamePhase == .playing else { return }
        timer?.invalidate()
        gamePhase = .paused
    }

    func resumeGame() {
        guard gamePhase == .paused else { return }
        gamePhase = .playing
        if isTimerBased {
            startGlobalTimer()
        }
    }

    func resetGame() {
        timer?.invalidate()
        gamePhase = .idle
    }
}
