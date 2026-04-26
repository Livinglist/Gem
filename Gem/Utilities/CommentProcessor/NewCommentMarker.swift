import SwiftData
import Foundation
import HackerNewsKit

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
            let models = try? context.fetch(descriptor)
            return Set(models?.first?.commentIds ?? [])
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
            try? context.save()
        }.value
        self.fetchedComments = Set<Int>(ids)
    }
    
    func process(_ comments: AsyncStream<Comment>) -> AsyncStream<Comment> {
        return AsyncStream { continuation in
            Task {
                var allComments = [Comment]()
                for await comment in comments {
                    let updatedComment = fetchedComments.isEmpty ? comment : comment.copyWith(isNew: !fetchedComments.contains(comment.id))
                    allComments.append(updatedComment)
                    continuation.yield(updatedComment)
                }
                await cacheCommentIds(allComments)
                continuation.finish()
            }
        }
    }
}
