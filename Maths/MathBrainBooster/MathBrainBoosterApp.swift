import SwiftUI

@main
struct MathBrainBoosterApp: App {
    @StateObject private var settings = SettingsViewModel.shared

    var body: some Scene {
        WindowGroup {
            HomeView()
                .preferredColorScheme(.dark)
        }
    }
}
