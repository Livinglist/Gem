import Logging
import Foundation
import InMemoryLogging

extension Logger {
    private static let bundleID = Bundle.main.bundleIdentifier.orEmpty
    private static let defaultLogger = Logger(label: bundleID)
    private static let devLogger = Logger(label: bundleID) { _ in
        MultiplexLogHandler([
            StreamLogHandler.standardOutput(label: bundleID),
            inMemoryHandler
        ])
    }
    static let inMemoryHandler = InMemoryLogHandler()
    static var shared: Logger = defaultLogger
    
    static func enableInMemoryLogHandler() {
        shared = devLogger
    }
    
    static func disableInMemoryLogHandler() {
        shared = defaultLogger
    }
}
