import GameKit
import SwiftUI

final class GameCenterManager: ObservableObject {
    static let shared = GameCenterManager()

    @Published var isAuthenticated = false
    @Published var isGameCenterEnabled = false

    private static let leaderboardIDs: [String: String] = [
        "addition_easy": "com.saturngames.mathbrainbooster.addition.easy",
        "addition_medium": "com.saturngames.mathbrainbooster.addition.medium",
        "addition_hard": "com.saturngames.mathbrainbooster.addition.hard",
        "addition_expert": "com.saturngames.mathbrainbooster.addition.expert",
        "subtraction_easy": "com.saturngames.mathbrainbooster.subtraction.easy",
        "multiplication_easy": "com.saturngames.mathbrainbooster.multiplication.easy",
        "division_easy": "com.saturngames.mathbrainbooster.division.easy",
        "mixed_easy": "com.saturngames.mathbrainbooster.mixed.easy",
        "overall_highscore": "com.saturngames.mathbrainbooster.overall",
    ]

    private init() {}

    func authenticate() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Game Center auth error: \(error.localizedDescription)")
                    self?.isAuthenticated = false
                    return
                }
                self?.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                self?.isGameCenterEnabled = GKLocalPlayer.local.isAuthenticated
            }
        }
    }

    func submitScore(_ score: Int, mode: GameMode, difficulty: Difficulty) {
        guard isAuthenticated else { return }

        let key = "\(mode.rawValue.lowercased())_\(difficulty.rawValue.lowercased())"
        guard let leaderboardID = Self.leaderboardIDs[key] ?? Self.leaderboardIDs["overall_highscore"] else { return }

        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [leaderboardID]) { error in
            if let error = error {
                print("Score submit error: \(error.localizedDescription)")
            }
        }

        if let overallID = Self.leaderboardIDs["overall_highscore"] {
            GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local, leaderboardIDs: [overallID]) { error in
                if let error = error {
                    print("Overall score submit error: \(error.localizedDescription)")
                }
            }
        }
    }

    func showLeaderboard(mode: GameMode? = nil, difficulty: Difficulty? = nil) {
        guard isAuthenticated else { return }
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        let gcVC = GKGameCenterViewController(state: .leaderboards)
        gcVC.gameCenterDelegate = GameCenterDismissHelper.shared
        rootVC.present(gcVC, animated: true)
    }
}

final class GameCenterDismissHelper: NSObject, GKGameCenterControllerDelegate {
    static let shared = GameCenterDismissHelper()
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}
