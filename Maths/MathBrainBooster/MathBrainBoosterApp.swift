import SwiftUI
import FirebaseCore
import GoogleMobileAds

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        // Fetch remote config early so values are ready for PaywallView
        RemoteConfigManager.shared.fetchConfig()
        return true
    }
}

@main
struct MathBrainBoosterApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var settings = SettingsViewModel.shared
    @AppStorage("hasSeenIntro") private var hasSeenIntro = false
    @AppStorage("hasSeenPostIntroPaywall") private var hasSeenPostIntroPaywall = false
    @State private var showSplash = true
    @State private var isHomeVisible = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if showSplash {
                    SplashScreenView {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSplash = false
                        }
                    }
                    .preferredColorScheme(.dark)
                } else if !hasSeenIntro {
                    IntroView()
                } else if !hasSeenPostIntroPaywall && !PaywallManager.shared.isProUser {
                    PaywallView(onClose: {
                        hasSeenPostIntroPaywall = true
                    })
                } else {
                    HomeView()
                        .preferredColorScheme(.dark)
                        .onAppear {
                            if !isHomeVisible {
                                isHomeVisible = true
                                // Load and show app open ad when home screen first appears
                                AppOpenAdManager.shared.loadAndShow()
                            }
                        }
                }
            }
                .task {
                    // Initialize Google Mobile Ads SDK (v13 async API)
                    await MobileAds.shared.start()

                    // Preload ads only for non-pro users
                    if !PaywallManager.shared.isProUserCached {
                        InterstitialAdManager.shared.loadAd()
                        RewardAdManager.shared.loadAd()
                        AppOpenAdManager.shared.loadAd()
                        ATTConsent.requestIfNeeded()
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .active && isHomeVisible {
                        // Show app open ad when user returns to the app
                        AppOpenAdManager.shared.showAdIfAvailable()
                    }
                }
        }
    }
}
