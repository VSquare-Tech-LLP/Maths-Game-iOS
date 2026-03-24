//
//  RewardAdManager.swift
//  MathBrainBooster
//

import Foundation
import GoogleMobileAds
import UIKit

@MainActor
final class RewardAdManager: ObservableObject {
    static let shared = RewardAdManager()

    // MARK: - Ad Unit IDs
    // Set to false for production (App Store release)
    private static let useTestAds = true

    private static let testAdUnitID = "ca-app-pub-3940256099942544/1712485313"
    private static let productionAdUnitID = "ca-app-pub-3997698054569290/7670119024"

    private var adUnitID: String {
        RewardAdManager.useTestAds
            ? RewardAdManager.testAdUnitID
            : RewardAdManager.productionAdUnitID
    }

    @Published private(set) var isRewardAdReady = false

    private var rewardedAd: RewardedAd?

    // MARK: - Reward Types

    enum RewardType: String {
        case doubleScore = "double_score"
        case extraTime = "extra_time"
        case skipQuestion = "skip_question"
        case extraChance = "extra_chance"
    }

    private init() {
        // Don't auto-load here; wait for MobileAds.shared.start() to complete.
        // loadAd() is called from MathBrainBoosterApp after SDK init.
    }

    // MARK: - Load Ad

    func loadAd() {
        RewardedAd.load(with: adUnitID, request: Request()) { [weak self] ad, error in
            Task { @MainActor in
                guard let self = self else { return }
                if let error = error {
                    print("[RewardAdManager] Failed to load: \(error.localizedDescription)")
                    self.isRewardAdReady = false
                    AnalyticsManager.shared.logAdEvent(event: "reward_ad_load_failed", adType: "rewarded")
                    return
                }
                self.rewardedAd = ad
                self.isRewardAdReady = true
                print("[RewardAdManager] Reward ad loaded successfully")
            }
        }
    }

    // MARK: - Show Ad

    /// Shows a rewarded ad. Calls `onReward` with the reward amount when the user finishes watching.
    /// - Parameters:
    ///   - rewardType: The type of reward to grant
    ///   - onReward: Callback with reward amount (called on main thread)
    ///   - onDismiss: Called when the ad is dismissed (whether or not reward was earned)
    func showAd(
        rewardType: RewardType = .doubleScore,
        onReward: @escaping (Int) -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        guard let ad = rewardedAd, isRewardAdReady else {
            print("[RewardAdManager] Reward ad not ready")
            loadAd()
            return
        }

        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController else {
            print("[RewardAdManager] No root view controller found")
            return
        }

        // Find the top-most presented view controller
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        ad.present(from: topVC) {
            let reward = ad.adReward
            let amount = Int(truncating: reward.amount)

            AnalyticsManager.shared.logAdEvent(
                event: "reward_earned",
                adType: "rewarded",
                rewardType: rewardType.rawValue,
                rewardAmount: amount
            )

            Task { @MainActor in
                onReward(amount)
            }
        }

        AnalyticsManager.shared.logAdEvent(event: "reward_ad_shown", adType: "rewarded")

        // Reset and preload next ad
        rewardedAd = nil
        isRewardAdReady = false
        loadAd()
    }
}
