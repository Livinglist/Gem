import Foundation

final actor Throttler {
    private let interval: TimeInterval
    private let trailing: Bool
 
    private var lastFireTime: Date = .distantPast
    private var pendingTask: Task<Void, Never>?
 
    /// - Parameters:
    ///   - interval: Minimum seconds between executions.
    ///   - trailing: If `true`, the last dropped call fires after the interval ends.
    init(interval: TimeInterval, trailing: Bool = false) {
        self.interval = interval
        self.trailing = trailing
    }
 
    nonisolated func callAsFunction(_ action: @escaping @Sendable () async -> Void) {
        Task {
            await throttle(action)
        }
    }
 
    func throttle(_ action: @escaping @Sendable () async -> Void) {
        let now = Date()
        let elapsed = now.timeIntervalSince(lastFireTime)
 
        // Cancel any pending trailing-edge task
        pendingTask?.cancel()
        pendingTask = nil
 
        if elapsed >= interval {
            // Leading edge — fire immediately
            lastFireTime = now
            Task { await action() }
        } else if trailing {
            // Trailing edge — schedule for the remainder of the interval
            let remaining = interval - elapsed
            pendingTask = Task {
                try? await Task.sleep(for: .seconds(remaining))
                guard !Task.isCancelled else { return }
                await action()
                self.lastFireTime = Date()
                self.pendingTask = nil
            }
        }
    }
}
