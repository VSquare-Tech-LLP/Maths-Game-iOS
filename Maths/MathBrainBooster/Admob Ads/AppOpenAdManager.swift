//
//  AppOpenAdManager.swift
//  MathBrainBooster
//

import Foundation
import GoogleMobileAds
import UIKit

@MainActor
final class AppOpenAdManager: NSObject, ObservableObject, FullScreenContentDelegate {
    static let shared = AppOpenAdManager()

    // MARK: - Ad Unit IDs
    // Set to false for production (App Store release)
    private static let useTestAds = true

    private static let testAdUnitID = "ca-app-pub-3940256099942544/5575463023"
    private static let productionAdUnitID = "ca-app-pub-3997698054569290/1926837752"

    private var adUnitID: String {
        AppOpenAdManager.useTestAds
            ? AppOpenAdManager.testAdUnitID
            : AppOpenAdManager.productionAdUnitID
    }

    @Published private(set) var isAdReady = false

    private var appOpenAd: AppOpenAd?
    private var isShowingAd = false
    private var isLoading = false
    private var loadTime: Date?

    /// Maximum time an ad can be cached before expiring (4 hours)
    private let adExpirationHours: TimeInterval = 4

    /// Callback when ad finishes (dismissed or failed)
    private var onAdFinished: (() -> Void)?

    /// If true, show ad as soon as it finishes loading
    private var showWhenReady = false

    /// Alternating counter — show ad every other time (0 = skip, 1 = show)
    private var openCount: Int {
        get { UserDefaults.standard.integer(forKey: "appOpenAdCount") }
        set { UserDefaults.standard.set(newValue, forKey: "appOpenAdCount") }
    }

    // MARK: - Init

    private override init() {
        super.init()
    }

    // MARK: - Load Ad

    func loadAd() {
        if PaywallManager.shared.isProUserCached { return }
        if isAdReady && !isAdExpired { return }
        if isLoading { return }

        isLoading = true
        print("[AppOpenAdManager] Loading ad...")

        AppOpenAd.load(with: adUnitID, request: Request()) { [weak self] ad, error in
            Task { @MainActor in
                guard let self = self else { return }
                self.isLoading = false

                if let error = error {
                    print("[AppOpenAdManager] Failed to load: \(error.localizedDescription)")
                    self.isAdReady = false
                    AnalyticsManager.shared.logAdEvent(event: "app_open_load_failed", adType: "app_open")
                    // If we were waiting to show, give up
                    if self.showWhenReady {
                        self.showWhenReady = false
                        let action = self.onAdFinished
                        self.onAdFinished = nil
                        action?()
                    }
                    return
                }

                self.appOpenAd = ad
                self.appOpenAd?.fullScreenContentDelegate = self
                self.isAdReady = true
                self.loadTime = Date()
                print("[AppOpenAdManager] Ad loaded successfully")

                // If someone requested to show ad while it was loading, show it now
                if self.showWhenReady {
                    self.showWhenReady = false
                    self.presentAd()
                }
            }
        }
    }

    // MARK: - Load & Show (for app open)

    /// Loads ad if needed and shows it as soon as ready. Use this on app open / HomeView appear.
    /// Shows ad on alternate opens only (1st skip, 2nd show, 3rd skip, 4th show...).
    func loadAndShow(onFinished: (() -> Void)? = nil) {
        if PaywallManager.shared.isProUserCached {
            onFinished?()
            return
        }

        guard !isShowingAd else {
            onFinished?()
            return
        }

        // Alternate: increment counter, show only on even counts
        openCount += 1
        if openCount % 2 == 0 {
            // Skip this time, but preload for next
            print("[AppOpenAdManager] Skipping (alternate), preloading for next open")
            loadAd()
            onFinished?()
            return
        }

        self.onAdFinished = onFinished

        if isAdReady && !isAdExpired {
            presentAd()
        } else {
            showWhenReady = true
            loadAd()
        }
    }

    // MARK: - Show Ad (when returning to foreground)

    /// Shows ad if already loaded. Does NOT wait for loading. Use for foreground return.
    /// Also alternates — only shows every other foreground return.
    func showAdIfAvailable(onFinished: (() -> Void)? = nil) {
        if PaywallManager.shared.isProUserCached {
            onFinished?()
            return
        }

        guard !isShowingAd else {
            onFinished?()
            return
        }

        // Alternate: increment counter, show only on even counts
        openCount += 1
        if openCount % 2 == 0 {
            print("[AppOpenAdManager] Skipping foreground ad (alternate), preloading")
            loadAd()
            onFinished?()
            return
        }

        guard isAdReady, !isAdExpired else {
            print("[AppOpenAdManager] Ad not ready or expired, skipping")
            loadAd()
            onFinished?()
            return
        }

        self.onAdFinished = onFinished
        presentAd()
    }

    // MARK: - Present Ad

    private func presentAd() {
        guard let ad = appOpenAd else {
            let action = onAdFinished
            onAdFinished = nil
            action?()
            return
        }

        guard let rootVC = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?
            .rootViewController else {
            print("[AppOpenAdManager] No root view controller found")
            let action = onAdFinished
            onAdFinished = nil
            action?()
            return
        }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        isShowingAd = true
        ad.present(from: topVC)
        AnalyticsManager.shared.logAdEvent(event: "app_open_shown", adType: "app_open")

        // Clear the ad reference so it's not reused
        appOpenAd = nil
        isAdReady = false
    }

    // MARK: - Ad Expiration

    private var isAdExpired: Bool {
        guard let loadTime = loadTime else { return true }
        let elapsed = Date().timeIntervalSince(loadTime) / 3600
        return elapsed >= adExpirationHours
    }

    // MARK: - FullScreenContentDelegate

    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            print("[AppOpenAdManager] Ad dismissed")
            self.isShowingAd = false
            let action = self.onAdFinished
            self.onAdFinished = nil
            action?()
            self.loadAd()
        }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            print("[AppOpenAdManager] Failed to present: \(error.localizedDescription)")
            self.isShowingAd = false
            let action = self.onAdFinished
            self.onAdFinished = nil
            action?()
            self.loadAd()
        }
    }

    nonisolated func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            print("[AppOpenAdManager] Ad will present")
        }
    }
}
