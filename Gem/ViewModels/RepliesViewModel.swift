import SwiftData
import SwiftUI
import HackerNewsKit
import BackgroundTasks
import Logging

private extension Calendar {
    func numberOfDaysBetween(_ from: Date, and to: Date) -> Int {
        let numberOfDays = dateComponents([.day], from: from, to: to)
        return numberOfDays.day ?? 0
    }
}

@MainActor
@Observable class RepliesViewModel {
    private let auth: Authentication = .shared
    private let repo: StoryRepository = .shared
    @ObservationIgnored private let modelConfig = ModelConfiguration("RepliesViewModel2")
    @ObservationIgnored private var container: ModelContainer?
    var fetchedComments = [Comment]()
    var newReplies = [Comment]()
    var status: Status = .idle
    
    static let shared: RepliesViewModel = .init()
    
    private init() {
        container = try? ModelContainer(for: RepliesModel.self, configurations: modelConfig)
        guard let container else { return }
        let context = container.mainContext
        var descriptor = FetchDescriptor<RepliesModel>()
        descriptor.fetchLimit = 1
        let models = try? context.fetch(descriptor)
        fetchedComments = models?.first?.fetchedReplies ?? []
        newReplies = models?.first?.newReplies ?? []
        Task(priority: .background) {
            await fetchAllReplies()
        }
        observeAuthState()
    }
    
    private func observeAuthState() {
        withObservationTracking {
            _ = auth.loggedIn
        } onChange: {
            DispatchQueue.main.async { [weak self] in
                if let isLoggedIn = self?.auth.loggedIn {                    
                    if isLoggedIn {
                        Task(priority: .background) {
                            await self?.fetchAllReplies()
                        }
                    } else {
                        self?.reset()
                    }
                }
                self?.observeAuthState()
            }
        }
    }
    
    private func reset() {
        fetchedComments.removeAll()
        newReplies.removeAll()
        saveToCache()
    }
    
    func scheduleFetching() {
        let request = BGAppRefreshTaskRequest(identifier: Constants.AppNotification.backgroundTaskId)
        request.earliestBeginDate = nil
        try? BGTaskScheduler.shared.submit(request)
    }

    func fetchAllReplies() async {
        if status.isLoading { return }
        status = .inProgress
        let lastPushedKey = Constants.AppNotification.lastItemPushedKey
        let lastFetchedKey = Constants.AppNotification.lastFetchedAtKey
        let lastPushedItemId = UserDefaults.standard.integer(forKey: lastPushedKey)
        let lastFetchedAt = UserDefaults.standard.integer(forKey: lastFetchedKey)
        let isFirstTime = lastFetchedAt == 0
        
        var fetchedReplies = [Comment]()
        var newReplies = [Comment]()
        
        if let username = auth.username,
           let user = await repo.fetchUser(username),
           let allSubmissions = user.submitted {
            let submissions = allSubmissions[0..<min(20, allSubmissions.count)]
            for submissionId in submissions {
                guard let item = await repo.fetchItem(submissionId) else { continue }
                let kids = item.kids ?? [Int]()
                let replies = await repo.fetchComments(ids: kids)
                fetchedReplies.append(contentsOf: replies)
            }
        } else {
            return
        }
        
        var updatedFetchedReplies = [Comment]()
        for reply in fetchedReplies {
            if self.newReplies.contains(reply) {
                newReplies.append(reply)
                updatedFetchedReplies.append(reply)
            } else if self.fetchedComments.contains(reply) {
                updatedFetchedReplies.append(reply)
            } else {
                updatedFetchedReplies.append(reply)
                newReplies.append(reply)
            }
        }
        
        updatedFetchedReplies.sort { $0.id > $1.id }
        newReplies.sort { $0.id > $1.id }
        
        let latestSubmittedItemId = newReplies.first?.id ?? 0
        
        if !isFirstTime && latestSubmittedItemId > lastPushedItemId {
            await push(id: latestSubmittedItemId)
            UserDefaults.standard.set(latestSubmittedItemId, forKey: Constants.AppNotification.lastItemPushedKey)
        }
        
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Constants.AppNotification.lastFetchedAtKey)

        self.fetchedComments = updatedFetchedReplies
        self.newReplies = newReplies
        self.status = .completed
        saveToCache()
        
        logger.info("All replies fetched: \(updatedFetchedReplies.count)")
        logger.info("New replies fetched: \(newReplies.count)")
    }
    
    func markAsRead(comment: Comment) {
        newReplies.removeAll { $0.id == comment.id }
        saveToCache()
    }
    
    func markAllAsRead() {
        newReplies = []
        saveToCache()
    }
    
    func refresh() async {
        await fetchAllReplies()
    }
    
    private func saveToCache() {
        let model = RepliesModel(fetchedReplies: fetchedComments, newReplies: newReplies)
        try? container?.mainContext.delete(model: RepliesModel.self)
        try? container?.mainContext.save()
        container?.mainContext.insert(model)
        try? container?.mainContext.save()
    }
    
    func push(id: Int) async {
        guard let item = await repo.fetchItem(id) else { return }
        let diff = Calendar.current.numberOfDaysBetween(item.createdAtDate, and: .now)
        
        // If a reply is more than 5 days old, we don't push it.
        if diff <= 5,
           let text = item.text,
           let author = item.by {
            let content = UNMutableNotificationContent()
            content.title = "from \(author):"
            content.body = text
            content.sound = UNNotificationSound.default
            content.targetContentIdentifier = String(item.id)

            let request = UNNotificationRequest(identifier: String(item.id), content: content, trigger: nil)
            try? await UNUserNotificationCenter.current().add(request)
            return
        }
    }
}
