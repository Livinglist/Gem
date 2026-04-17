import Foundation
import Combine
import SwiftUI
import Alamofire
import HackerNewsKit

@MainActor
@Observable
class ItemStore : ObservableObject {
    var comments: [Comment] = .init()
    var searchResults: [Int] = .init()
    var status: Status = .idle
    var item: (any Item)?
    var loadingItemId: Int?

    /// Stores ids of loaded comments, including both root and child comments.
    var loadedCommentIds: Set<Int> = .init()
    var isRecursivelyFetching: Bool = SettingsStore.shared.defaultFetchMode == .eager || OfflineRepository.shared.isOfflineReading {
        didSet {
            if OfflineRepository.shared.isOfflineReading {
                return
            }
        }
    }
    
    private var cache = NSCache<NSNumber, CommentCollection>()

    /// Load child comments of a comment.
    func loadKids(of cmt: Comment) async {
        if let parentIndex = comments.firstIndex(of: cmt),
           let kids = cmt.kids,
           let level = cmt.level,
           loadingItemId == nil {
            self.loadingItemId = cmt.id
            
            var comments = [Comment]()
            
            if !OfflineRepository.shared.isOfflineReading {
                let newComments = await StoryRepository.shared.fetchComments(ids: kids).map { $0.copyWith(level: level + 1)}
                comments.append(contentsOf: newComments)
            } else if let id = loadingItemId {
                comments = OfflineRepository.shared.fetchComments(of: id)
            }
            
            withAnimation {
                self.loadingItemId = nil
                self.loadedCommentIds.insert(cmt.id)
                self.comments.insert(contentsOf: comments, at: parentIndex + 1)
            }
        }
    }
    
    func refresh() async -> Void {
        guard let item = self.item, !status.isLoading else { return }
        let id = item.id
        
        if item is Comment || item.descendants.orZero > 0 {
            HapticsManager.shared.playLoadingHaptics()
        }
        
        defer {
            HapticsManager.shared.stop()
            self.status = .completed
        }
        
        withAnimation {
            self.comments = []
        }
        self.loadingItemId = nil
        self.loadedCommentIds = []
        self.status = .inProgress
        var commentsBuffer = [Comment]()
        
        if OfflineRepository.shared.isOfflineReading {
            // We don't need to refresh in offline mode
            if !self.comments.isEmpty { self.status = .completed }
            let cmts = OfflineRepository.shared.fetchComments(of: id)
            self.comments = cmts
            self.status = .completed
        } else {
            if let item = await StoryRepository.shared.fetchItem(id),
               let kids = item.kids {
                self.item = item
                if isRecursivelyFetching {
                    let source: CommentSource = item is Comment ? .API : .web
                    do {
                        let comments = try await StoryRepository.shared.fetchCommentsRecursively(of: item, from: source)
                        withAnimation {
                            self.comments = comments
                        }
                    } catch {
                        let hasCache = getFromCache()
                        if !hasCache {
                            if let comments = try? await StoryRepository.shared.fetchCommentsRecursively(of: item, from: source == .API ? .web : .API) {
                                withAnimation {
                                    self.comments = comments
                                }
                            }
                        }
                    }
                } else {
                    let comments = await StoryRepository.shared.fetchComments(ids: kids).map { $0.copyWith(level: 0) }
                    withAnimation {
                        self.comments = comments
                    }
                }
            }
        }
    }
    
    private func saveToCache() {
        guard let itemId = item?.id, !comments.isEmpty else { return }
        let key = NSNumber(integerLiteral: itemId)
        let commentCollection = CommentCollection(comments, parentId: itemId)
        cache.setObject(commentCollection, forKey: key)
    }
    
    private func getFromCache() -> Bool {
        guard let itemId = item?.id else { return  false }
        let cachedComments = cache.object(forKey: .init(integerLiteral: itemId))
        if let cachedComments {
            comments = cachedComments.comments
            return true
        } else {
            return false
        }
    }
    
    func fetchParent(of cmt: Comment) async {
        guard let parentId = cmt.parent,
              let parent = await StoryRepository.shared.fetchItem(parentId)
        else { return }
        
        Router.shared.to(parent)
    }
    
    func collapse(cmt: Comment) {
        Task.detached(priority: .background) { [self] in
            var commentsBuffer = await Array(comments)
            func sendUpdates() async {
                await MainActor.run { [commentsBuffer] in
                    withAnimation {
                        self.comments = commentsBuffer
                    }
                }
            }
            guard await status.isCompleted else { return }
            var updatedCommentsSlice = [Comment]()
            let updatedComment = cmt.copyWith(isCollapsed: true)
            let parentIndex = commentsBuffer.firstIndex { $0.id == cmt.id }
            let parentLevel = cmt.level
            updatedCommentsSlice.append(updatedComment)
            guard let parentIndex, let parentLevel else { return }
            commentsBuffer.replaceSubrange(parentIndex..<parentIndex + 1, with: [updatedComment])
            var index = parentIndex + 1
            guard index < commentsBuffer.count else {
                await sendUpdates()
                return
            }
            var nextComment = commentsBuffer[index]
            var nextCommentLevel: Int = nextComment.level ?? 0
            guard nextCommentLevel > parentLevel else {
                await sendUpdates()
                return
            }
            repeat {
                let updatedComment = nextComment.copyWith(isHidden: true)
                commentsBuffer.replaceSubrange(index..<index + 1, with: [updatedComment])
                index = index + 1
                guard index < commentsBuffer.count else { break }
                nextComment = commentsBuffer[index]
                nextCommentLevel = nextComment.level ?? 0
            } while (nextCommentLevel > parentLevel)

            await sendUpdates()
        }
    }
    
    func uncollapse(cmt: Comment) {
        guard status.isCompleted else { return }
        var updatedCommentsSlice = [Comment]()
        let updatedComment = cmt.copyWith(isCollapsed: false)
        let parentIndex = comments.firstIndex { $0.id == cmt.id }
        let parentLevel = cmt.level
        updatedCommentsSlice.append(updatedComment)
        guard let parentIndex, let parentLevel else { return }
        comments.replaceSubrange(parentIndex..<parentIndex + 1, with: [updatedComment])
        var index = parentIndex + 1
        guard index < comments.count else { return }
        var nextComment = comments[index]
        var nextCommentLevel: Int = nextComment.level ?? 0
        guard nextCommentLevel > parentLevel else { return }
        repeat {
            let updatedComment = nextComment.copyWith(isHidden: false)
            comments.replaceSubrange(index..<index + 1, with: [updatedComment])
            index = index + 1
            guard index < comments.count else { return }
            nextComment = comments[index]
            nextCommentLevel = nextComment.level ?? 0
        } while (nextCommentLevel > parentLevel)
    }
    
    func searchInThread(_ text: String) {
        var results = [Int]()
        for index in 0..<comments.count {
            let comment = comments[index]
            if let commentText = comment.text, commentText.localizedCaseInsensitiveContains(text) {
                results.append(index)
            }
        }
        self.searchResults = results
    }
}
