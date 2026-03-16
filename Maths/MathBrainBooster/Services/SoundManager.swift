import AVFoundation
import SwiftUI

final class SoundManager: ObservableObject {
    static let shared = SoundManager()

    @Published var isSoundEnabled: Bool {
        didSet { UserDefaults.standard.set(isSoundEnabled, forKey: "soundEnabled") }
    }

    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var synthesizer = AVSpeechSynthesizer()

    private init() {
        self.isSoundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") as? Bool ?? true
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }

    func playCorrect() {
        guard isSoundEnabled else { return }
        playSystemSound(id: 1025)
    }

    func playWrong() {
        guard isSoundEnabled else { return }
        playSystemSound(id: 1073)
    }

    func playGameOver() {
        guard isSoundEnabled else { return }
        playSystemSound(id: 1521)
    }

    func playCountdown() {
        guard isSoundEnabled else { return }
        playSystemSound(id: 1113)
    }

    func playAchievement() {
        guard isSoundEnabled else { return }
        playSystemSound(id: 1335)
    }

    func playButtonTap() {
        guard isSoundEnabled else { return }
        playSystemSound(id: 1104)
    }

    func playStreakMilestone() {
        guard isSoundEnabled else { return }
        playSystemSound(id: 1301)
    }

    private func playSystemSound(id: SystemSoundID) {
        AudioServicesPlaySystemSound(id)
    }
}
