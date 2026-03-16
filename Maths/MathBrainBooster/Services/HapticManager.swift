import CoreHaptics
import UIKit

final class HapticManager: ObservableObject {
    static let shared = HapticManager()

    @Published var isHapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(isHapticsEnabled, forKey: "hapticsEnabled") }
    }

    private var engine: CHHapticEngine?
    private let supportsHaptics: Bool

    private init() {
        self.isHapticsEnabled = UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
        self.supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics
        setupEngine()
    }

    private func setupEngine() {
        guard supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
            try engine?.start()
        } catch {
            print("Haptic engine error: \(error)")
        }
    }

    func correctAnswer() {
        guard isHapticsEnabled else { return }
        if supportsHaptics {
            playPattern(intensity: 0.6, sharpness: 0.5, duration: 0.15)
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    func wrongAnswer() {
        guard isHapticsEnabled else { return }
        if supportsHaptics {
            playErrorPattern()
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    func streakMilestone() {
        guard isHapticsEnabled else { return }
        if supportsHaptics {
            playStreakPattern()
        } else {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
    }

    func buttonTap() {
        guard isHapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    func gameOver() {
        guard isHapticsEnabled else { return }
        if supportsHaptics {
            playGameOverPattern()
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        }
    }

    func achievement() {
        guard isHapticsEnabled else { return }
        if supportsHaptics {
            playAchievementPattern()
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func playPattern(intensity: Float, sharpness: Float, duration: TimeInterval) {
        guard supportsHaptics, let engine = engine else { return }
        let event = CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
            ],
            relativeTime: 0,
            duration: duration
        )
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Haptic play error: \(error)")
        }
    }

    private func playErrorPattern() {
        guard supportsHaptics, let engine = engine else { return }
        let events = [
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
            ], relativeTime: 0),
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
            ], relativeTime: 0.1)
        ]
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Haptic error pattern: \(error)")
        }
    }

    private func playStreakPattern() {
        guard supportsHaptics, let engine = engine else { return }
        let events = (0..<3).map { i in
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(i + 1) * 0.3),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ], relativeTime: TimeInterval(i) * 0.08)
        }
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Haptic streak error: \(error)")
        }
    }

    private func playGameOverPattern() {
        guard supportsHaptics, let engine = engine else { return }
        let events = [
            CHHapticEvent(eventType: .hapticContinuous, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            ], relativeTime: 0, duration: 0.4)
        ]
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Haptic game over error: \(error)")
        }
    }

    private func playAchievementPattern() {
        guard supportsHaptics, let engine = engine else { return }
        let events = (0..<4).map { i in
            CHHapticEvent(eventType: .hapticTransient, parameters: [
                CHHapticEventParameter(parameterID: .hapticIntensity, value: min(1.0, Float(i + 1) * 0.25)),
                CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4 + Float(i) * 0.15)
            ], relativeTime: TimeInterval(i) * 0.1)
        }
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Haptic achievement error: \(error)")
        }
    }
}
