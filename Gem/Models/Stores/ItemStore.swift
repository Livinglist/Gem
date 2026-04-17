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
    var actionPerformed: Action = .none
    var timeDisplay: TimeDisplay = .timeAgo

    /// Stores ids of loaded comments, including both root and child comments.
    var loadedCommentIds: Set<Int> = .init()
    var collapsed: Set<Int> = .init()
    var hidden: Set<Int> = .init()
    var isRecursivelyFetching: Bool = SettingsStore.shared.defaultFetchMode == .eager || OfflineRepository.shared.isOfflineReading {
        didSet {
            if OfflineRepository.shared.isOfflineReading {
                return
            }
            actionPerformed = isRecursivelyFetching ? .eagerFetching : .lazyFetching
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
                await StoryRepository.shared.fetchComments(ids: kids) { comment in
                    comments.append(comment.copyWith(level: level + 1))
                }
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
        
        withAnimation {
            self.comments.removeAll()
        }
        
        self.loadingItemId = nil
        self.loadedCommentIds.removeAll()
        self.collapsed.removeAll()
        self.hidden.removeAll()
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
                    do {
                        try await StoryRepository.shared.fetchCommentsRecursively(from: item) { comment in
                            DispatchQueue.main.async {
                                if let comment = comment {
                                    self.status = .backgroundLoading

                                    commentsBuffer.append(comment)
                                } else {
                                    withAnimation {
                                        self.comments = commentsBuffer
                                        self.saveToCache()
                                    }
                                    self.status = .completed
                                }
                            }
                        }
                    } catch is FetchError {
                        getFromCache()
                    } catch {
                        // fetch using API
                    }
                } else {
                    await StoryRepository.shared.fetchComments(ids: kids) { comment in
                        DispatchQueue.main.async {
                            self.status = .backgroundLoading
                            self.comments.append(comment.copyWith(level: 0))
                        }
                    }
                }
            }
            self.status = .completed
        }
    }
    
    private func saveToCache() {
        guard let itemId = item?.id, !comments.isEmpty else { return }
        let key = NSNumber(integerLiteral: itemId)
        let commentCollection = CommentCollection(comments, parentId: itemId)
        cache.setObject(commentCollection, forKey: key)
    }
    
    private func getFromCache() {
        guard let itemId = item?.id else { return }
        let cachedComments = cache.object(forKey: .init(integerLiteral: itemId))
        comments = cachedComments?.comments ?? []
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
                guard index < commentsBuffer.count else { return }
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
