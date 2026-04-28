import SwiftData
import Foundation
import HackerNewsKit
import Logging

fileprivate extension ModelContainer {
    static let threadCache: ModelContainer? = {
        let storageUrl = URL.cachesDirectory.appending(path: "cache.sqlite")
        let config = ModelConfiguration("ThreadCache", url: storageUrl, cloudKitDatabase: .none)
        return try? ModelContainer(for: ThreadCacheModel.self, configurations: config)
    }()
}

class NewCommentMarker: CommentProcessor {
    private let container: ModelContainer?
    let parentId: Int
    var fetchedComments = Set<Int>()
    
    init(parentId: Int) {
        self.parentId = parentId
        self.container = .threadCache
        
        Task {
            await initializeCache()
        }
    }
    
    private func initializeCache() async {
        let id = parentId
        let comments = await Task.detached(priority: .userInitiated) {
            guard let container = await ModelContainer.threadCache else { return Set<Int>() }
            let context = ModelContext(container)
            var descriptor = FetchDescriptor<ThreadCacheModel>(
                predicate: #Predicate { $0.parentId == id }
            )
            descriptor.fetchLimit = 1
            do {
                let models = try context.fetch(descriptor)
                return Set(models.first?.commentIds ?? [])
            } catch {
                await Logger.shared.error("Error fetching comments IDs cache:", error: error)
            }
            return Set()
        }.value
        self.fetchedComments = comments
    }
    
    private func cacheCommentIds(_ comments: [Comment]) async {
        let ids = comments.map { $0.id }
        await Task.detached(priority: .userInitiated) {
            guard let container = await ModelContainer.threadCache else { return }
            let context = ModelContext(container)
            let model = ThreadCacheModel(ids, parentId: self.parentId)
            context.insert(model)
            do {
                try context.save()
            } catch {
                await Logger.shared.error("Error saving comments IDs:", error: error)
            }
        }.value
    }
    
    func process(_ comments: AsyncStream<(Int, Comment)>) -> AsyncStream<(Int, Comment)> {
        return AsyncStream { continuation in
            Task {
                var allComments = [Comment]()
                for await entry in comments {
                    let index = entry.0
                    let comment = entry.1
                    let updatedComment = fetchedComments.isEmpty ? comment : comment.copyWith(isNew: !fetchedComments.contains(comment.id))
                    allComments.append(updatedComment)
                    continuation.yield((index, updatedComment))
                }
                await cacheCommentIds(allComments)
                continuation.finish()
            }
        }
    }
}
