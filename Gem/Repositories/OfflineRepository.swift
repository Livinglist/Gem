import Alamofire
import BackgroundTasks
import Combine
import Foundation
import SwiftUI
import SwiftData
import HackerNewsKit

/// 
/// For accessing cached stories and comments when the device is offline.
///
@MainActor
@Observable public class OfflineRepository {
    var isDownloading = false
    var isOfflineReading = false {
        didSet {
            if !isInMemory {
                loadIntoMemory()
            }
        }
    }
    var completionCount = 0
    
    var lastFetchedAt: String {
        guard let date = UserDefaults.standard.object(forKey: lastDownloadAtKey) as? Date else { return "" }
        let df = DateFormatter()
        df.dateFormat = "MM/dd/yyyy HH:mm"
        return df.string(from: date)
    }
    var isInMemory = false
    
    private let storyRepository = StoryRepository(session: Session())
    private let container = try! ModelContainer(for: StoryCollection.self, CommentCollection.self)
    private let downloadOrder = [StoryType.top, .ask, .best]
    private let lastDownloadAtKey = "lastDownloadedAt"
    private var stories = [StoryType: [Story]]()
    private var comments = [Int: [Comment]]()
    private var networkStatusSubscription: AnyCancellable?

    public static let shared: OfflineRepository = .init()
    
    init() {
        networkStatusSubscription = NetworkMonitor.shared.networkStatus
            .receive(on: RunLoop.main)
            .removeDuplicates()
            .sink { isConnected in
                guard let isConnected = isConnected else { return }
                if !isConnected && !self.isInMemory {
                    self.loadIntoMemory()
                }
            }
    }
    
    public func loadIntoMemory() {
        let context = container.mainContext
        
        // Fetch all cached stories.
        var descriptor = FetchDescriptor<StoryCollection>()
        descriptor.fetchLimit = downloadOrder.count
        if let results = try? context.fetch(descriptor) {
            for res in results {
                stories[res.storyType] = res.stories
            }
        }
        
        // Fetch all cached comments.
        let cmtDescriptor = FetchDescriptor<CommentCollection>()
        if let results = try? context.fetch(cmtDescriptor) {
            for collection in results {
                comments[collection.parentId] = collection.comments
            }
        }
        
        isInMemory = true
    }
    
    public func scheduleBackgroundDownload() {
        let downloadTask = BGProcessingTaskRequest(identifier: Constants.Download.backgroundTaskId)
        // Set earliestBeginDate to be 1 day from now.
        downloadTask.earliestBeginDate = Date(timeIntervalSinceNow: 86400)
        downloadTask.requiresNetworkConnectivity = true
        downloadTask.requiresExternalPower = true
        do {
            try BGTaskScheduler.shared.submit(downloadTask)
        } catch {
            debugPrint("Unable to submit task: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Story related.

    public func abortDownload() -> Void {
        isDownloading = false
    }

    public func downloadAllStories(isTriggerdByUser: Bool) async -> Void {
        let settings = SettingsStore.shared

        /// Initiate download process if:
        /// - process is triggered by user action.
        /// or:
        /// - process is triggered by the system and the network status is satisfied.
        guard isTriggerdByUser || (settings.isAutomaticDownloadEnabled && (settings.useCellularData || NetworkMonitor.shared.isOnWifi)) else { return }

        isDownloading = true
        
        UserDefaults.standard.set(Date.now, forKey: lastDownloadAtKey)
        
        let context = container.mainContext
        var completedStoryId = Set<Int>()
        
        if isTriggerdByUser {
            try? context.delete(model: StoryCollection.self)
            try? context.delete(model: CommentCollection.self)
        }
        
        for storyType in downloadOrder {
            var stories = [Story]()
            
            let results = await storyRepository.fetchAllStories(from: storyType)
            stories.append(contentsOf: results)
            context.insert(StoryCollection(stories, storyType: storyType))

            // Fetch comments for each story concurrently.
            await withTaskGroup(of: Int?.self) { group in
                for story in stories {
                    guard isDownloading else { break }
                    guard !completedStoryId.contains(story.id) else { continue }

                    group.addTask {
                        await self.downloadChildComments(of: story, level: 0)
                        return story.id
                    }
                }

                for await completedId in group {
                    guard isDownloading else {
                        group.cancelAll()
                        return
                    }
                    guard let completedId else { continue }
                    completionCount += 1
                    completedStoryId.insert(completedId)
                }
            }
        }
        
        isDownloading = false
    }
    
    private func downloadChildComments(of item: any Item, level: Int) async -> Void {
        let context = container.mainContext
        let comments = await fetchComments(ids: item.kids ?? [Int]()).map { $0.copyWith(level: level) }
        context.insert(CommentCollection(comments, parentId: item.id))
        try? context.save()
        
        for comment in comments {
            await downloadChildComments(of: comment, level: level + 1)
        }
    }
    
    private func fetchComments(ids: [Int]) async -> [Comment] {
        let comments: [Comment] = await withTaskGroup(of: (Int, Comment?).self) { group in
            for (index, id) in ids.enumerated() {
                group.addTask { [self] in
                    guard let comment = await storyRepository.fetchComment(id) else { return (index, nil) }
                    return (index, comment)
                }
            }
            
            var comments: [(Int, Comment?)] = []
            for await result in group {
                guard isDownloading else {
                    group.cancelAll()
                    return []
                }
                comments.append(result)
            }
            return comments
                .sorted { $0.0 < $1.0 }
                .compactMap { $0.1 }
        }
        return comments
    }
    
    public func fetchAllStories(from storyType: StoryType) -> [Story] {
        guard let stories = stories[storyType] else { return [Story]() }
        let storiesWithCommentsDownloaded = stories.filter { story in
            comments[story.id].isNotNullOrEmpty
        }
        return storiesWithCommentsDownloaded
    }
    
    // MARK: - Comment related.
    
    public func fetchComments(of id: Int) -> [Comment] {
        var results = [Comment]()

        func fetch(_ id: Int, level: Int) {
            let cmts = comments[id]?.map { $0.copyWith(level: level) } ?? []

            for cmt in cmts {
                results.append(cmt.copyWith(level: level))
                fetch(cmt.id, level: level + 1)
            }
        }

        fetch(id, level: 0)

        return results
    }
}
