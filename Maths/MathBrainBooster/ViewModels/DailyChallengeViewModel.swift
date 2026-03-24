import Foundation
import SwiftUI

@MainActor
final class DailyChallengeViewModel: ObservableObject {
    static let shared = DailyChallengeViewModel()

    @Published var challenge: DailyChallenge
    @Published var currentRoundIndex: Int = 0
    @Published var phase: DailyChallengePhase = .overview
    @Published var roundStats: [GameStats] = []
    @Published var currentStats = GameStats()
    @Published var currentQuestion: Question?
    @Published var timeRemaining: TimeInterval = 0
    @Published var totalTime: TimeInterval = 0
    @Published var questionNumber: Int = 0
    @Published var countdownValue: Int = 3
    @Published var lastAnswerCorrect: Bool?
    @Published var showAnswerFeedback = false
    @Published var selectedAnswer: Int?

    @Published var isTodayCompleted: Bool = false
    @Published var todayScore: Int = 0
    @Published var currentDayStreak: Int = 0
    @Published var bestDayStreak: Int = 0

    private var timer: Timer?
    private let challengeKey = "dailyChallenge"
    private let streakKey = "dailyChallengeStreak"
    private let bestStreakKey = "dailyChallengeBestStreak"
    private let lastCompletedKey = "dailyChallengeLastCompleted"

    private init() {
        self.challenge = DailyChallenge.forToday()
        loadState()
    }

    var currentRound: DailyChallengeRound? {
        guard currentRoundIndex < challenge.rounds.count else { return nil }
        return challenge.rounds[currentRoundIndex]
    }

    var totalRounds: Int { challenge.rounds.count }

    var overallScore: Int {
        roundStats.reduce(0) { $0 + $1.totalScore }
    }

    var overallAccuracy: Double {
        let total = roundStats.reduce(0) { $0 + $1.questionsAnswered }
        let correct = roundStats.reduce(0) { $0 + $1.correctAnswers }
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total) * 100
    }

    var overallBestStreak: Int {
        roundStats.map { $0.bestStreak }.max() ?? 0
    }

    var timerProgress: CGFloat {
        guard totalTime > 0 else { return 1 }
        return CGFloat(timeRemaining / totalTime)
    }

    var timerColor: Color {
        let progress = timerProgress
        if progress > 0.5 { return .green }
        if progress > 0.25 { return .yellow }
        return .red
    }

    func startChallenge() {
        guard !isTodayCompleted else {
            phase = .results
            return
        }
        currentRoundIndex = 0
        roundStats = []
        phase = .roundIntro
        AnalyticsManager.shared.logDailyChallengeStarted()
    }

    func resetChallenge() {
        timer?.invalidate()
        isTodayCompleted = false
        todayScore = 0
        currentRoundIndex = 0
        roundStats = []
        currentStats = GameStats()
        currentQuestion = nil
        questionNumber = 0
        lastAnswerCorrect = nil
        showAnswerFeedback = false
        selectedAnswer = nil
        challenge = DailyChallenge.forToday()
        phase = .overview

        // Clear saved completion for today
        UserDefaults.standard.removeObject(forKey: challengeKey)
    }

    func startCurrentRound() {
        guard let round = currentRound else { return }
        currentStats = GameStats()
        questionNumber = 0
        phase = .countdown
        countdownValue = 3

        SoundManager.shared.playCountdown()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.countdownValue -= 1
                if self.countdownValue > 0 {
                    SoundManager.shared.playCountdown()
                } else {
                    self.timer?.invalidate()
                    self.phase = .playing
                    self.nextQuestion(round: round)
                }
            }
        }
    }

    private func nextQuestion(round: DailyChallengeRound) {
        // Prevent stale delayed calls from executing
        guard phase == .playing else { return }
        guard questionNumber < round.questionsCount else {
            finishRound()
            return
        }

        questionNumber += 1
        lastAnswerCorrect = nil
        showAnswerFeedback = false
        selectedAnswer = nil
        currentQuestion = Question.generate(mode: round.mode, difficulty: round.difficulty)

        totalTime = round.difficulty.timePerQuestion
        timeRemaining = totalTime
        startTimer(round: round)
    }

    private func startTimer(round: DailyChallengeRound) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.timeRemaining -= 0.05
                if self.timeRemaining <= 0 {
                    self.timeRemaining = 0
                    self.handleTimeout(round: round)
                }
            }
        }
    }

    func selectAnswer(_ answer: Int) {
        guard phase == .playing, !showAnswerFeedback, let round = currentRound else { return }
        timer?.invalidate()
        selectedAnswer = answer

        let isCorrect = answer == currentQuestion?.correctAnswer
        lastAnswerCorrect = isCorrect
        showAnswerFeedback = true
        currentStats.questionsAnswered += 1
        AnalyticsManager.shared.logAnswerSubmitted(isCorrect: isCorrect, currentStreak: currentStats.currentStreak, mode: round.mode)

        if isCorrect {
            currentStats.correctAnswers += 1
            currentStats.currentStreak += 1
            currentStats.bestStreak = max(currentStats.bestStreak, currentStats.currentStreak)
            updateMultiplier()
            currentStats.totalScore += round.difficulty.pointsPerCorrect * currentStats.multiplier
            SoundManager.shared.playCorrect()
            HapticManager.shared.correctAnswer()

            if currentStats.currentStreak > 0 && currentStats.currentStreak % 5 == 0 {
                SoundManager.shared.playStreakMilestone()
                HapticManager.shared.streakMilestone()
            }
        } else {
            currentStats.wrongAnswers += 1
            currentStats.currentStreak = 0
            currentStats.multiplier = 1
            SoundManager.shared.playWrong()
            HapticManager.shared.wrongAnswer()

            if let q = currentQuestion, let round = currentRound {
                MistakesManager.shared.addMistake(
                    questionText: q.text,
                    correctAnswer: q.correctAnswer,
                    userAnswer: answer,
                    mode: round.mode,
                    difficulty: round.difficulty
                )
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            self.nextQuestion(round: round)
        }
    }

    private func handleTimeout(round: DailyChallengeRound) {
        // CRITICAL: Invalidate timer first to prevent repeated calls
        timer?.invalidate()

        // Guard against re-entry
        guard phase == .playing, !showAnswerFeedback else { return }

        currentStats.questionsAnswered += 1
        currentStats.wrongAnswers += 1
        currentStats.currentStreak = 0
        currentStats.multiplier = 1
        lastAnswerCorrect = false
        showAnswerFeedback = true
        SoundManager.shared.playWrong()
        HapticManager.shared.wrongAnswer()

        if let q = currentQuestion {
            MistakesManager.shared.addMistake(
                questionText: q.text,
                correctAnswer: q.correctAnswer,
                userAnswer: nil,
                mode: round.mode,
                difficulty: round.difficulty
            )
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            self.nextQuestion(round: round)
        }
    }

    private func updateMultiplier() {
        if currentStats.currentStreak >= 10 {
            currentStats.multiplier = 3
        } else if currentStats.currentStreak >= 5 {
            currentStats.multiplier = 2
        } else {
            currentStats.multiplier = 1
        }
    }

    private func finishRound() {
        timer?.invalidate()
        roundStats.append(currentStats)
        currentRoundIndex += 1

        if currentRoundIndex < challenge.rounds.count {
            phase = .roundIntro
        } else {
            completeChallenge()
        }
    }

    private func completeChallenge() {
        phase = .results
        isTodayCompleted = true
        todayScore = overallScore
        challenge = DailyChallenge(
            date: challenge.date,
            seed: challenge.seed,
            rounds: challenge.rounds,
            isCompleted: true,
            totalScore: overallScore,
            accuracy: overallAccuracy,
            bestStreak: overallBestStreak
        )

        updateStreak()
        saveState()

        // Record activity for streak tracking
        StreakManager.shared.recordActivity()

        SoundManager.shared.playAchievement()
        HapticManager.shared.achievement()
        AnalyticsManager.shared.logDailyChallengeCompleted(score: overallScore, accuracy: overallAccuracy,
                                                           bestStreak: overallBestStreak, dayStreak: currentDayStreak)

        // Show interstitial ad every few games
        InterstitialAdManager.shared.gameCompleted()
    }

    private func updateStreak() {
        let today = DailyChallenge.todayString()
        let lastCompleted = UserDefaults.standard.string(forKey: lastCompletedKey) ?? ""

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        if let lastDate = formatter.date(from: lastCompleted),
           let todayDate = formatter.date(from: today) {
            let diff = Calendar.current.dateComponents([.day], from: lastDate, to: todayDate).day ?? 0
            if diff == 1 {
                currentDayStreak += 1
            } else if diff > 1 {
                currentDayStreak = 1
            }
        } else {
            currentDayStreak = 1
        }

        bestDayStreak = max(bestDayStreak, currentDayStreak)

        UserDefaults.standard.set(today, forKey: lastCompletedKey)
        UserDefaults.standard.set(currentDayStreak, forKey: streakKey)
        UserDefaults.standard.set(bestDayStreak, forKey: bestStreakKey)
    }

    private func saveState() {
        if let data = try? JSONEncoder().encode(challenge) {
            UserDefaults.standard.set(data, forKey: challengeKey)
        }
    }

    private func loadState() {
        currentDayStreak = UserDefaults.standard.integer(forKey: streakKey)
        bestDayStreak = UserDefaults.standard.integer(forKey: bestStreakKey)

        if let data = UserDefaults.standard.data(forKey: challengeKey),
           let saved = try? JSONDecoder().decode(DailyChallenge.self, from: data),
           saved.date == DailyChallenge.todayString() {
            self.challenge = saved
            self.isTodayCompleted = saved.isCompleted
            self.todayScore = saved.totalScore
        } else {
            self.challenge = DailyChallenge.forToday()
            self.isTodayCompleted = false
            self.todayScore = 0
        }
    }

    func pauseGame() {
        guard phase == .playing else { return }
        timer?.invalidate()
        phase = .paused
    }

    func resumeGame() {
        guard phase == .paused, let round = currentRound else { return }
        phase = .playing
        startTimer(round: round)
    }

    func resetForNewDay() {
        challenge = DailyChallenge.forToday()
        currentRoundIndex = 0
        roundStats = []
        phase = .overview
        loadState()
    }
}

enum DailyChallengePhase {
    case overview
    case roundIntro
    case countdown
    case playing
    case paused
    case roundComplete
    case results
}
