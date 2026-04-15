import Foundation
import Combine
import SwiftUI
import HackerNewsKit

extension Thread {
    enum TimeDisplay {
        case timeAgo
        case dateTime

        mutating func toggle() {
            if self == .timeAgo {
                self = .dateTime
            } else {
                self = .timeAgo
            }
        }
    }
}

extension Thread {
    @MainActor
    class ItemStore : ObservableObject {
        @Published var comments: [Comment] = .init()
        @Published var status: Status = .idle
        @Published var item: (any Item)?
        @Published var loadingItemId: Int?
        @Published var actionPerformed: Action = .none
        @Published var timeDisplay: TimeDisplay = .timeAgo

        /// Stores ids of loaded comments, including both root and child comments.
        @Published var loadedCommentIds: Set<Int> = .init()
        @Published var collapsed: Set<Int> = .init()
        @Published var hidden: Set<Int> = .init()
        @Published var isRecursivelyFetching: Bool = SettingsStore.shared.defaultFetchMode == .eager || OfflineRepository.shared.isOfflineReading {
            didSet {
                if OfflineRepository.shared.isOfflineReading {
                    return
                }
                actionPerformed = isRecursivelyFetching ? .eagerFetching : .lazyFetching
            }
        }

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
                        await StoryRepository.shared.fetchCommentsRecursively(from: item) { comment in
                            DispatchQueue.main.async {
                                if let comment = comment {
                                    self.status = .backgroundLoading

                                    commentsBuffer.append(comment)
                                } else {
                                    withAnimation {
                                        self.comments = commentsBuffer
                                    }
                                    self.status = .completed
                                }
                            }
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
        
        private func hide(kidsOf parent: Comment) {
            guard let kids = parent.kids else { return }
            
            for childId in kids {
                let child = self.comments.first { $0.id == childId }
                guard let child = child else {
                    continue
                }
                hidden.insert(childId)
                hide(kidsOf: child)
            }
        }
        
        private func unhide(kidsOf parent: Comment) {
            guard let kids = parent.kids else { return }
            
            for childId in kids {
                let child = self.comments.first { $0.id == childId }
                guard let child = child else {
                    continue
                }
                
                hidden.remove(childId)
                if collapsed.contains(childId) == false {
                    unhide(kidsOf: child)
                }
            }
        }
    }
}
