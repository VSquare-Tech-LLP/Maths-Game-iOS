//
//  RemoteConfigManager.swift
//  MathBrainBooster
//

import Foundation
import FirebaseRemoteConfig

@MainActor
final class RemoteConfigManager: ObservableObject {
    static let shared = RemoteConfigManager()

    @Published var defaultPlanSelected: Int = 1

    private let remoteConfig = RemoteConfig.remoteConfig()

    private init() {
        // Set defaults (used when fetch hasn't completed or fails)
        let defaults: [String: NSObject] = [
            "DefaultPlanSelected": NSNumber(value: 1)
        ]
        remoteConfig.setDefaults(defaults)

        // Fetch interval = 0 so every fetchConfig() call gets fresh values
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig.configSettings = settings
    }

    /// Fetch and activate remote config values
    func fetchConfig() {
        remoteConfig.fetchAndActivate { [weak self] status, error in
            Task { @MainActor in
                guard let self = self else { return }
                if let error = error {
                    print("[RemoteConfig] Fetch failed: \(error.localizedDescription)")
                    return
                }

                let planValue = self.remoteConfig.configValue(forKey: "DefaultPlanSelected").numberValue.intValue
                // Ensure value is valid (0-based index, at least 0)
                self.defaultPlanSelected = max(0, planValue)
                print("[RemoteConfig] DefaultPlanSelected = \(self.defaultPlanSelected)")
            }
        }
    }
}
