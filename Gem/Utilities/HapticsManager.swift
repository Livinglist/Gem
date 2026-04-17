import CoreHaptics
import UIKit

class HapticsManager {
    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?
    
    static let shared = HapticsManager()

    init() {
        setupEngine()
    }
    
    private func setupEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        engine = try? CHHapticEngine()
        engine?.resetHandler = { [weak self] in
            try? self?.engine?.start()
        }
        engine?.stoppedHandler = { [weak self] _ in
            self?.engine = nil
            self?.player = nil
            self?.setupEngine()
        }
        try? engine?.start()
    }
    
    func stop() {
        Task {
            try? player?.stop(atTime: CHHapticTimeImmediate)
        }
    }
    
    func playLoadingHaptics() {
        if let player {
            try? player.start(atTime: CHHapticTimeImmediate)
        } else {
            guard let path = Bundle.main.path(forResource: "heartbeats", ofType: "ahap") else {
                return
            }
            guard let pattern = try? CHHapticPattern(contentsOf: URL(fileURLWithPath: path)) else {
                return
            }
            player = try? engine?.makeAdvancedPlayer(with: pattern)
            player?.loopEnabled = true
            player?.loopEnd = 2
            try? player?.start(atTime: CHHapticTimeImmediate)
        }
    }

    func playCustomHaptic() {
        guard let engine, CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        let events = [
            CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0
            ),
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0.1,
                duration: 0.3
            )
        ]

        guard let pattern = try? CHHapticPattern(events: events, parameters: []),
              let player = try? engine.makePlayer(with: pattern) else { return }
        try? player.start(atTime: 0)
    }
}
