//
//  InterstitialAdManager.swift
//  MathBrainBooster
//

import Foundation
import GoogleMobileAds
import UIKit

@MainActor
final class InterstitialAdManager: NSObject, ObservableObject, FullScreenContentDelegate {
    static let shared = InterstitialAdManager()

    // MARK: - Ad Unit IDs
    // ⚙️ Set to false for production (App Store release)
    private static let useTestAds = true

    private static let testAdUnitID = "ca-app-pub-3940256099942544/4411468910"
    private static let productionAdUnitID = "ca-app-pub-3997698054569290/6826843047"

    private var adUnitID: String {
        InterstitialAdManager.useTestAds
            ? InterstitialAdManager.testAdUnitID
            : InterstitialAdManager.productionAdUnitID
    }

    @Published private(set) var isAdReady = false

    private var interstitialAd: InterstitialAd?

    // MARK: - Game Counter (shows ad after every N game completions)
    private var gamesPlayedSinceLastAd: Int {
        get { UserDefaults.standard.integer(forKey: "gamesPlayedSinceLastAd") }
        set { UserDefaults.standard.set(newValue, forKey: "gamesPlayedSinceLastAd") }
    }
    /// Number of games between each interstitial ad
    private let gamesPerAd = 3

    // MARK: - Button Click Counter (shows ad after every N button clicks on HomeView)
    private var buttonClickCount: Int {
        get { UserDefaults.standard.integer(forKey: "buttonClicksSinceLastAd") }
        set { UserDefaults.standard.set(newValue, forKey: "buttonClicksSinceLastAd") }
    }

    // ✏️ CHANGE THIS VALUE to control how many clicks before interstitial shows (default: 2)
    private let clicksPerAd = 3

    /// Stored action to run after the ad is dismissed (e.g. navigate to a screen)
    private var onAdDismissed: (() -> Void)?

    // MARK: - Init

    private override init() {
        super.init()
        // Don't auto-load here; wait for MobileAds.shared.start() to complete.
        // loadAd() is called from MathBrainBoosterApp after SDK init.
    }

    // MARK: - Load Ad

    func loadAd() {
        // Don't load ads for pro users
        if PaywallManager.shared.isProUserCached { return }

        InterstitialAd.load(with: adUnitID, request: Request()) { [weak self] ad, error in
            Task { @MainActor in
                guard let self = self else { return }
                if let error = error {
                    print("[InterstitialAdManager] Failed to load: \(error.localizedDescription)")
                    self.isAdReady = false
                    AnalyticsManager.shared.logAdEvent(event: "interstitial_load_failed", adType: "interstitial")
                    return
                }
                self.interstitialAd = ad
                self.interstitialAd?.fullScreenContentDelegate = self
                self.isAdReady = true
                print("[InterstitialAdManager] Ad loaded successfully")
            }
        }
    }

    // MARK: - Game Completed Trigger

    /// Call this when a game ends. Shows interstitial every `gamesPerAd` games.
    /// Pro users never see interstitial ads.
    func gameCompleted() {
        if PaywallManager.shared.isProUserCached { return }

        gamesPlayedSinceLastAd += 1

        if gamesPlayedSinceLastAd >= gamesPerAd {
            showAd(onDismiss: nil)
            gamesPlayedSinceLastAd = 0
        }
    }

    // MARK: - Button Click Trigger (HomeView)

    /// Call this when any navigation button is tapped on HomeView.
    /// Always navigates immediately via `onComplete`, then shows ad on top if counter reached.
    /// When ad closes, the target screen is already visible underneath — no home screen flash.
    /// Pro users skip ads entirely.
    func buttonClicked(onComplete: @escaping () -> Void) {
        if PaywallManager.shared.isProUserCached {
            onComplete()
            return
        }

        buttonClickCount += 1
        if buttonClickCount >= clicksPerAd {
            buttonClickCount = 0
            // Navigate FIRST so the target screen is underneath
            onComplete()
            // Show ad on top after the screen has presented (~0.5s for fullScreenCover animation)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) { [weak self] in
                self?.showAd(onDismiss: nil)
            }
        } else {
            onComplete()
        }
    }

    // MARK: - Show Ad

    /// Shows the interstitial ad from the top-most view controller.
    /// `onDismiss` is called after the ad closes (or immediately if ad can't show).
    func showAd(onDismiss: (() -> Void)?) {
        guard let ad = interstitialAd, isAdReady else {
            print("[InterstitialAdManager] Ad not ready, skipping")
            loadAd()
            onDismiss?()
            return
        }

        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController else {
            print("[InterstitialAdManager] No root view controller found")
            onDismiss?()
            return
        }

        // Find the top-most presented view controller
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        // Store the completion for when ad dismisses
        self.onAdDismissed = onDismiss

        ad.present(from: topVC)
        AnalyticsManager.shared.logAdEvent(event: "interstitial_shown", adType: "interstitial")

        // Reset and preload next ad
        interstitialAd = nil
        isAdReady = false
        loadAd()
    }

    // MARK: - FullScreenContentDelegate

    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            print("[InterstitialAdManager] Ad dismissed")
            let action = self.onAdDismissed
            self.onAdDismissed = nil
            action?()
        }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            print("[InterstitialAdManager] Failed to present: \(error.localizedDescription)")
            let action = self.onAdDismissed
            self.onAdDismissed = nil
            action?()
            self.loadAd()
        }
    }

    // MARK: - Force Show (bypass game counter)

    /// Force shows an interstitial regardless of game count (e.g., on app resume).
    /// Pro users are exempt.
    func forceShowAd() {
        if PaywallManager.shared.isProUserCached { return }
        showAd(onDismiss: nil)
        gamesPlayedSinceLastAd = 0
    }
}
