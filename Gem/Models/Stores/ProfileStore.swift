import SwiftUI
import HackerNewsKit

extension Profile {
    @MainActor
    class ProfileStore: ObservableObject {
        @Published var user: User?
        @Published var status: Status = .idle
        @ObservedObject var settingsStore: SettingsStore = .shared

        func fetchUser(id: String) async {
            self.status = .inProgress
            let user = await StoryRepository.shared.fetchUser(id)
            
            if let user = user {
                self.user = user
                self.status = .completed
            }
        }

        var isBlocked: Bool {
            if let user = self.user, let id = user.id, id != Authentication.shared.username {
                return self.settingsStore.blocklist.contains(id)
            }
            return false
        }

        func block() {
            if let user = self.user, let id = user.id, id != Authentication.shared.username {
                self.settingsStore.block(id)
            }
        }

        func unblock() {
            if let user = self.user, let id = user.id, id != Authentication.shared.username {
                self.settingsStore.unblock(id)
            }
        }
    }
}
