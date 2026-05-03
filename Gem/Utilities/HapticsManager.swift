import CoreHaptics
import UIKit

class HapticsManager {
    private var engine: CHHapticEngine?
    private var player: CHHapticAdvancedPatternPlayer?
    private var boingPlayer: CHHapticAdvancedPatternPlayer?
    
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
            self?.boingPlayer = nil
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
        do {
            if let player {
                try player.start(atTime: CHHapticTimeImmediate)
            } else {
                guard let path = Bundle.main.path(forResource: "heartbeats", ofType: "ahap") else {
                    return
                }
                let pattern = try CHHapticPattern(contentsOf: URL(fileURLWithPath: path))
                player = try engine?.makeAdvancedPlayer(with: pattern)
                player?.loopEnabled = true
                try player?.start(atTime: CHHapticTimeImmediate)
            }
        } catch {
            setupEngine()
        }
    }
    
    func boing() {
        do {
            if let boingPlayer {
                try boingPlayer.start(atTime: CHHapticTimeImmediate)
            } else {
                guard let path = Bundle.main.path(forResource: "boing", ofType: "ahap") else {
                    return
                }
                let pattern = try CHHapticPattern(contentsOf: URL(fileURLWithPath: path))
                boingPlayer = try engine?.makeAdvancedPlayer(with: pattern)
                try boingPlayer?.start(atTime: CHHapticTimeImmediate)
            }
        } catch {
            setupEngine()
        }
    }
}
