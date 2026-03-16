import Foundation

struct Achievement: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let description: String
    let icon: String
    var isUnlocked: Bool
    var unlockedDate: Date?

    static let allAchievements: [Achievement] = [
        Achievement(id: "first_game", title: "First Steps", description: "Complete your first game", icon: "figure.walk", isUnlocked: false),
        Achievement(id: "perfect_round", title: "Perfect Round", description: "Get 100% accuracy in a game", icon: "crown.fill", isUnlocked: false),
        Achievement(id: "streak_10", title: "On Fire", description: "Reach a 10 answer streak", icon: "flame.fill", isUnlocked: false),
        Achievement(id: "streak_25", title: "Unstoppable", description: "Reach a 25 answer streak", icon: "bolt.heart.fill", isUnlocked: false),
        Achievement(id: "score_1000", title: "High Scorer", description: "Score 1000 points in one game", icon: "trophy.fill", isUnlocked: false),
        Achievement(id: "all_modes", title: "Versatile", description: "Play all 6 game modes", icon: "star.circle.fill", isUnlocked: false),
        Achievement(id: "expert_complete", title: "Math Genius", description: "Complete an Expert difficulty game", icon: "graduationcap.fill", isUnlocked: false),
        Achievement(id: "games_50", title: "Dedicated", description: "Complete 50 games total", icon: "medal.fill", isUnlocked: false),
    ]
}
