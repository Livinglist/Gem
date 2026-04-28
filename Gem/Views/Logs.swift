import SwiftUI
import Logging
import InMemoryLogging

struct Logs: View {
    let logs = Logger.inMemoryHandler.entries.map { LogEntryWrapper(id: UUID(), entry: $0) }
    
    struct LogEntryWrapper: Identifiable {
        let id: UUID
        let entry: InMemoryLogHandler.Entry
    }
    
    var body: some View {
        List {
            ForEach(logs) { log in
                VStack(alignment: .leading) {
                    Text(log.entry.message.description)
                    if !log.entry.metadata.isEmpty {
                        Text(log.entry.metadata.description)
                            .font(.footnote)
                            .foregroundStyle(.gray)
                    }
                    if let error = log.entry.error {
                        Text(error.localizedDescription)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }
        }
    }
}
