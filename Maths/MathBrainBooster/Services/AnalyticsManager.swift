import Foundation
import FirebaseAnalytics

final class AnalyticsManager {
    static let shared = AnalyticsManager()
    private init() {}

    // MARK: - Event Names

    private enum Event {
        static let gameStarted = "game_started"
        static let answerSubmitted = "answer_submitted"
        static let gameCompleted = "game_completed"
        static let gamePaused = "game_paused"
        static let gameResumed = "game_resumed"
        static let dailyChallengeStarted = "daily_challenge_started"
        static let dailyChallengeCompleted = "daily_challenge_completed"
        static let quickMathsStarted = "quick_maths_started"
        static let quickMathsCompleted = "quick_maths_completed"
        static let miniGameStarted = "mini_game_started"
        static let achievementUnlocked = "achievement_unlocked"
        static let screenViewed = "screen_viewed"
        static let settingsChanged = "settings_changed"
    }

    // MARK: - Parameter Keys

    private enum Param {
        static let mode = "mode"
        static let difficulty = "difficulty"
        static let score = "score"
        static let accuracy = "accuracy"
        static let bestStreak = "best_streak"
        static let correctAnswers = "correct_answers"
        static let totalQuestions = "total_questions"
        static let isCorrect = "is_correct"
        static let currentStreak = "current_streak"
        static let timerMode = "timer_mode"
        static let questionLimit = "question_limit"
        static let gameName = "game_name"
        static let achievementId = "achievement_id"
        static let screenName = "screen_name"
        static let settingName = "setting_name"
        static let settingValue = "setting_value"
        static let dayStreak = "day_streak"
    }

    // MARK: - Game Lifecycle

    func logGameStarted(mode: GameMode, difficulty: Difficulty) {
        Analytics.logEvent(Event.gameStarted, parameters: [
            Param.mode: mode.rawValue,
            Param.difficulty: difficulty.rawValue
        ])
    }

    func logAnswerSubmitted(isCorrect: Bool, currentStreak: Int, mode: GameMode) {
        Analytics.logEvent(Event.answerSubmitted, parameters: [
            Param.isCorrect: isCorrect,
            Param.currentStreak: currentStreak,
            Param.mode: mode.rawValue
        ])
    }

    func logGameCompleted(mode: GameMode, difficulty: Difficulty, score: Int,
                          accuracy: Double, bestStreak: Int,
                          correctAnswers: Int, totalQuestions: Int) {
        Analytics.logEvent(Event.gameCompleted, parameters: [
            Param.mode: mode.rawValue,
            Param.difficulty: difficulty.rawValue,
            Param.score: score,
            Param.accuracy: accuracy,
            Param.bestStreak: bestStreak,
            Param.correctAnswers: correctAnswers,
            Param.totalQuestions: totalQuestions
        ])
    }

    func logGamePaused(mode: GameMode) {
        Analytics.logEvent(Event.gamePaused, parameters: [
            Param.mode: mode.rawValue
        ])
    }

    func logGameResumed(mode: GameMode) {
        Analytics.logEvent(Event.gameResumed, parameters: [
            Param.mode: mode.rawValue
        ])
    }

    // MARK: - Daily Challenge

    func logDailyChallengeStarted() {
        Analytics.logEvent(Event.dailyChallengeStarted, parameters: nil)
    }

    func logDailyChallengeCompleted(score: Int, accuracy: Double,
                                     bestStreak: Int, dayStreak: Int) {
        Analytics.logEvent(Event.dailyChallengeCompleted, parameters: [
            Param.score: score,
            Param.accuracy: accuracy,
            Param.bestStreak: bestStreak,
            Param.dayStreak: dayStreak
        ])
    }

    // MARK: - Quick Maths

    func logQuickMathsStarted(mode: GameMode, difficulty: Difficulty,
                               timerMode: String, questionLimit: String) {
        Analytics.logEvent(Event.quickMathsStarted, parameters: [
            Param.mode: mode.rawValue,
            Param.difficulty: difficulty.rawValue,
            Param.timerMode: timerMode,
            Param.questionLimit: questionLimit
        ])
    }

    func logQuickMathsCompleted(mode: GameMode, difficulty: Difficulty,
                                 score: Int, accuracy: Double,
                                 bestStreak: Int, totalQuestions: Int) {
        Analytics.logEvent(Event.quickMathsCompleted, parameters: [
            Param.mode: mode.rawValue,
            Param.difficulty: difficulty.rawValue,
            Param.score: score,
            Param.accuracy: accuracy,
            Param.bestStreak: bestStreak,
            Param.totalQuestions: totalQuestions
        ])
    }

    // MARK: - Mini Games

    func logMiniGameStarted(gameName: String) {
        Analytics.logEvent(Event.miniGameStarted, parameters: [
            Param.gameName: gameName
        ])
    }

    // MARK: - Achievements

    func logAchievementUnlocked(achievementId: String) {
        Analytics.logEvent(Event.achievementUnlocked, parameters: [
            Param.achievementId: achievementId
        ])
    }

    // MARK: - Screen Views

    func logScreenViewed(screenName: String) {
        Analytics.logEvent(Event.screenViewed, parameters: [
            Param.screenName: screenName
        ])
    }

    // MARK: - Settings

    func logSettingsChanged(setting: String, value: String) {
        Analytics.logEvent(Event.settingsChanged, parameters: [
            Param.settingName: setting,
            Param.settingValue: value
        ])
    }

    // MARK: - Ads

    func logAdEvent(event: String, adType: String, rewardType: String? = nil, rewardAmount: Int? = nil) {
        var params: [String: Any] = ["ad_type": adType]
        if let rewardType = rewardType {
            params["reward_type"] = rewardType
        }
        if let rewardAmount = rewardAmount {
            params["reward_amount"] = rewardAmount
        }
        Analytics.logEvent(event, parameters: params)
    }
}
