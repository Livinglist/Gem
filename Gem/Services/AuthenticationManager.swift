import Combine
import SwiftData
import Logging
import Foundation
import HackerNewsKit

fileprivate extension ModelContainer {
    static let userModel: ModelContainer? = {
        let config = ModelConfiguration("AuthenticationManager")
        return try? ModelContainer(for: UserModel.self, configurations: config)
    }()
}

@MainActor
@Observable public class AuthenticationManager {
    var user: User?
    
    var username: String? {
        user?.id
    }
    
    var loggedIn: Bool {
        user != nil
    }
    
    @ObservationIgnored private let container: ModelContainer?
    
    static let shared: AuthenticationManager = .init()
    
    private init() {
        Logger.shared.info("Initializing auth state...")
        
        self.container = .userModel
        if let container {
            let context = container.mainContext
            var userFetchDescriptor = FetchDescriptor<UserModel>()
            userFetchDescriptor.fetchLimit = 1
            let results = try? context.fetch(userFetchDescriptor)
            user = results?.first?.user
        }
        
        let username = AuthRepository.shared.username
        Task {
            guard let username = username, username.isNotEmpty else { return }
            self.user = User(id: username)
            if let user = await StoryRepository.shared.fetchUser(username) {
                self.user = user
                saveToCache()
            }
            Logger.shared.info("Logged in as \(username)")
        }
    }
    
    func logIn(username: String, password: String, shouldRememberMe: Bool) async -> Bool {
        let loggedIn = await AuthRepository.shared.logIn(username: username, password: password, shouldRememberMe: shouldRememberMe)
        guard loggedIn else { return false }
        self.user = await StoryRepository.shared.fetchUser(username)
        saveToCache()
        return loggedIn
    }
    
    func logOut() {
        _ = AuthRepository.shared.logOut()
        self.user = nil
        saveToCache()
    }

    func flag(_ id: Int) async -> Bool {
        return await AuthRepository.shared.flag(id)
    }

    func upvote(_ id: Int) async -> Bool {
        return await AuthRepository.shared.upvote(id)
    }
    
    func downvote(_ id: Int) async -> Bool {
        return await AuthRepository.shared.downvote(id)
    }
    
    func favorite(_ id: Int) async -> Bool {
        if loggedIn {
            return await AuthRepository.shared.fav(id)
        }
        return false
    }
    
    func unfavorite(_ id: Int) async -> Bool {
        if loggedIn {
            return await AuthRepository.shared.unfav(id)
        }
        return false
    }
    
    func reply(to id: Int, with text: String) async -> Bool {
        return await AuthRepository.shared.reply(to: id, with: text)
    }
    
    func edit(_ id: Int, with text: String) async -> Bool {
        return await AuthRepository.shared.edit(id, with: text)
    }
    
    private func saveToCache() {
        do {
            let model = UserModel(user: user)
            try container?.mainContext.delete(model: UserModel.self)
            try container?.mainContext.save()
            container?.mainContext.insert(model)
            try container?.mainContext.save()
        } catch {
            Logger.shared.error("Error saving user to cache:", error: error)
        }
    }
}
