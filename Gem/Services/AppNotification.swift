import SwiftUI
import HackerNewsKit
import BackgroundTasks

private extension Calendar {
    func numberOfDaysBetween(_ from: Date, and to: Date) -> Int {
        let numberOfDays = dateComponents([.day], from: from, to: to)
        return numberOfDays.day ?? 0
    }
}

@MainActor
class AppNotification {
    private let auth: Authentication = .shared
    private let repo: StoryRepository = .shared
    
    static let shared: AppNotification = .init()
    
    private init() {}
    
    func scheduleFetching() {
        let request = BGAppRefreshTaskRequest(identifier: Constants.AppNotification.backgroundTaskId)
        request.earliestBeginDate = nil
        try? BGTaskScheduler.shared.submit(request)
    }

    func fetchAllReplies() async {
        let lastPushedKey = Constants.AppNotification.lastItemPushedKey
        let lastFetchedKey = Constants.AppNotification.lastFetchedAtKey
        let lastPushedItemId = UserDefaults.standard.integer(forKey: lastPushedKey)
        let lastFetchedAt = UserDefaults.standard.integer(forKey: lastFetchedKey)
        let isFirstTime = lastFetchedAt == 0
        
        var newlyFetchedReplies = [Int]()
        
        if let username = auth.username,
           let user = await repo.fetchUser(username),
           let allSubmissions = user.submitted {
            let submissions = allSubmissions[0..<min(10, allSubmissions.count)]
            for submissionId in submissions {
                guard let item = await repo.fetchItem(submissionId) else { continue }
                let itemCreatedAt = item.createdAtDate
                let diff = Calendar.current.numberOfDaysBetween(itemCreatedAt, and: .now)
                
                // If a user's submission is from more than 5 days ago, we ignore it.
                if diff >= 5 { continue }
                
                let kids = item.kids ?? [Int]()
                for kid in kids {
                    newlyFetchedReplies.append(kid)
                }
            }
        }
        
        newlyFetchedReplies.sort()
        
        let latestSubmittedItemId = newlyFetchedReplies.last ?? 0
        
        if !isFirstTime && latestSubmittedItemId > lastPushedItemId {
            await push(id: latestSubmittedItemId)
            UserDefaults.standard.set(latestSubmittedItemId, forKey: Constants.AppNotification.lastItemPushedKey)
        }
        
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: Constants.AppNotification.lastFetchedAtKey)
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
