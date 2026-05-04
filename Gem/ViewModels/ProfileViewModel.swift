import SwiftUI
import HackerNewsKit
import Combine

extension Profile {
    @MainActor
    @Observable class ProfileViewModel {
        var user: User?
        var status: Status = .idle
        let settings: SettingsViewModel = .shared

        func fetchUser(id: String) async {
            self.status = .inProgress
            let user = await StoryRepository.shared.fetchUser(id)
            
            if let user = user {
                self.user = user
                self.status = .completed
            }
        }

        var isBlocked: Bool {
            if let user = self.user, let id = user.id, id != AuthenticationManager.shared.username {
                return self.settings.blocklist.contains(id)
            }
            return false
        }

        func block() {
            if let user = self.user, let id = user.id, id != AuthenticationManager.shared.username {
                self.settings.block(id)
            }
        }

        func unblock() {
            if let user = self.user, let id = user.id, id != AuthenticationManager.shared.username {
                self.settings.unblock(id)
            }
        }
    }
}
