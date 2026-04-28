import Foundation
import SwiftData
import Combine
import SwiftUI
import Alamofire
import HackerNewsKit
import Translation

@MainActor
@Observable class ThreadViewModel {
    /// The root of this thread, can be a comment or story.
    var item: (any Item)?
    
    /// The comments displayed on thread screen.
    var comments: [Comment] = .init()
    
    /// Comments cache for switching back to untranslated comments from translated comments.
    @ObservationIgnored
    var buffer: [Comment] = .init()
    
    /// The loading state of comments.
    var status: Status = .idle
    
    /// The ID of comment that the scroll view on thread screen is about to scroll to.
    var scrollTo: Int?
    
    // MARK: - Translation
    var isTranslationEnabled: Bool = false {
        didSet {
            if isTranslationEnabled {
                translate()
            } else {
                untranslate()
            }
        }
    }
    var targetLanguage: Locale.Language = .englishUS
    var translationStatus: Status = .idle
    
    // MARK: - In-thread Search Options
    var isNewSelected: Bool = false {
        didSet {
            searchInThread(inThreadSearchQuery)
        }
    }
    var isByOpSelected: Bool = false {
        didSet {
            searchInThread(inThreadSearchQuery)
        }
    }
    var searchResults: [Int] = .init()
    @ObservationIgnored
    private var inThreadSearchQuery = ""
    
    // MARK: - Lazy and recursive fetching
    /// Stores ids of loaded comments, including both root and child comments.
    var loadedCommentIds: Set<Int> = .init()
    /// The id of comment of which the leaf comments are being fetched in lazy fetching.
    var loadingItemId: Int?
    /// Whether or not the comments are fetched lazily or recursively.
    var isRecursivelyFetching: Bool = SettingsViewModel.shared.defaultFetchMode == .eager || OfflineRepository.shared.isOfflineReading {
        didSet {
            if OfflineRepository.shared.isOfflineReading {
                return
            }
        }
    }
    
    // MARK: - Factory
    /// Streamlined factory to handle comment text translation, new comments marking, and markdown pre-rendering.
    @ObservationIgnored
    private var factory: CommentFactory = .init(processors: [])
    /// The factory processing task.
    @ObservationIgnored
    private var streamTask: Task<Void, Never>?
    
    // MARK: - Cache
    /// Comments cache to fall back to when all resorts exhausted...
    @ObservationIgnored
    private var commentsCache = NSCache<NSNumber, CommentCollection>()
    
    init(_ item: any Item) {
        self.item = item
        if item is Story {
            factory = .init(processors: [
                NewCommentMarker(parentId: item.id),
                MarkdownParser(language: .englishUS)
            ])
        } else {
            factory = .init(processors: [
                MarkdownParser(language: .englishUS)
            ])
        }
    }
    
    /// Load child comments of a comment.
    func loadKids(of cmt: Comment) async {
        guard translationStatus != .inProgress else { return }
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
            
            var buffer = [Comment]()
            for await entry in factory.process(comments) {
                let comment = entry.1
                buffer.append(comment)
            }
            
            withAnimation {
                self.loadingItemId = nil
                self.loadedCommentIds.insert(cmt.id)
                self.comments.insert(contentsOf: buffer, at: parentIndex + 1)
            }
        }
    }
    
    func refresh() async -> Void {
        guard let item = self.item, !status.isLoading else { return }
        var commentsBuffer = [Comment]()
        defer {
            HapticsManager.shared.stop()
            saveToCache()
            self.status = .completed
            self.comments = commentsBuffer
        }
        
        // Cancel any existing task
        streamTask?.cancel()
        
        // Initialize processors
        var processors: [CommentProcessor] = []
        if let story = item as? Story {
            processors.append(NewCommentMarker(parentId: story.id))
        }
        if isTranslationEnabled, let translator = CommentTranslator(targetLanguage: targetLanguage) {
            processors.append(translator)
        }
        processors.append(MarkdownParser(language: targetLanguage))
        factory = .init(processors: processors)
        
        // If kids are not empty, start playing haptics
        if item is Comment || item.descendants.orZero > 0 {
            HapticsManager.shared.playLoadingHaptics()
        }
        
        // If fetching lazily, reset leaves
        if !isRecursivelyFetching {
            loadedCommentIds = Set<Int>()
        }
        
        // Remove all existing comments before fetching
        withAnimation {
            self.comments = []
            self.status = .inProgress
        }
        
        if OfflineRepository.shared.isOfflineReading {
            let cmts = OfflineRepository.shared.fetchComments(of: item.id)
            commentsBuffer = cmts
        } else {
            if let item = await StoryRepository.shared.fetchItem(item.id),
               let kids = item.kids {
                self.item = item
                if isRecursivelyFetching {
                    let source: CommentSource = item is Comment ? .API : .web
                    do {
                        commentsBuffer = try await StoryRepository.shared.fetchCommentsRecursively(of: item, from: source)
                    } catch {
                        if let comments = try? await StoryRepository.shared.fetchCommentsRecursively(of: item, from: source == .API ? .web : .API) {
                            commentsBuffer = comments
                        } else {
                            _ =  getFromCache()
                        }
                    }
                } else {
                    commentsBuffer = await StoryRepository.shared.fetchComments(ids: kids).map { $0.copyWith(level: 0) }
                }
            }
        }
        
        buffer = commentsBuffer
        for await entry in factory.process(commentsBuffer) {
            let index = entry.0
            let comment = entry.1
            commentsBuffer[index] = comment
        }
    }
    
    private func saveToCache() {
        guard let itemId = item?.id, !comments.isEmpty else { return }
        let key = NSNumber(integerLiteral: itemId)
        let commentCollection = CommentCollection(comments, parentId: itemId)
        commentsCache.setObject(commentCollection, forKey: key)
    }
    
    private func getFromCache() -> Bool {
        guard let itemId = item?.id else { return  false }
        let cachedComments = commentsCache.object(forKey: .init(integerLiteral: itemId))
        if let cachedComments {
            comments = cachedComments.comments
            return true
        } else {
            return false
        }
    }
    
    func goToParent() async {
        guard let parentId = item?.parent,
              let parent = await StoryRepository.shared.fetchItem(parentId)
        else { return }
        
        Router.shared.to(parent)
    }
    
    func collapse(cmt: Comment) {
        guard status.isCompleted else { return }
        var commentsBuffer = comments
        Task { [self] in
            let updatedComment = cmt.copyWith(isCollapsed: true)
            let parentIndex = commentsBuffer.firstIndex { $0.id == cmt.id }
            let parentLevel = cmt.level
            func sendUpdates() async {
                await MainActor.run { [commentsBuffer] in
                    withAnimation(.snappy.speed(200)) {
                        self.comments = commentsBuffer
                    }
                    self.scrollTo = cmt.id
                }
            }
            guard let parentIndex, let parentLevel else { return }
            commentsBuffer[parentIndex] = updatedComment
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
                commentsBuffer[index] = updatedComment
                index = index + 1
                guard index < commentsBuffer.count else { break }
                nextComment = commentsBuffer[index]
                nextCommentLevel = nextComment.level ?? 0
            } while (nextCommentLevel > parentLevel)
            
            await sendUpdates()
        }
    }
    
    func uncollapse(cmt: Comment) async {
        guard status.isCompleted else { return }
        var commentsBuffer = comments
        func sendUpdates() async {
            await MainActor.run { [commentsBuffer] in
                withAnimation(.snappy.speed(200)) {
                    self.comments = commentsBuffer
                }
            }
        }
        let updatedComment = cmt.copyWith(isCollapsed: false)
        let parentIndex = commentsBuffer.firstIndex { $0.id == cmt.id }
        let parentLevel = cmt.level
        guard let parentIndex, let parentLevel else { return }
        commentsBuffer[parentIndex] = updatedComment
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
        
        // Uncollapse comments until the next same-level comment is reached
        repeat {
            let updatedComment = nextComment.copyWith(isHidden: false)
            commentsBuffer[index] = updatedComment
            // If the comment is collapsed, skip to the next comment on the same level
            if updatedComment.isCollapsed ?? false {
                repeat {
                    index = index + 1
                    guard index < commentsBuffer.count else {
                        await sendUpdates()
                        return
                    }
                    nextComment = commentsBuffer[index]
                    nextCommentLevel = nextComment.level ?? 0
                } while nextCommentLevel > updatedComment.level.orZero
            }
            // If the comment is not collapsed, proceed to the next one
            else {
                index = index + 1
                guard index < commentsBuffer.count else {
                    await sendUpdates()
                    return
                }
                nextComment = commentsBuffer[index]
                nextCommentLevel = nextComment.level ?? 0
            }
        } while (nextCommentLevel > parentLevel)
        
        await sendUpdates()
    }
    
    func uncollapseRoot(of index: Int) async {
        var comment: Comment? = comments[index]
        guard var isHidden = comment?.isHidden,
              var isCollapsed = comment?.isCollapsed,
              isHidden || isCollapsed else { return }
        repeat {
            if comment != nil {
                if isCollapsed {
                    await uncollapse(cmt: comment!)
                }
                
                if isHidden {
                    comment = comments.first { $0.id == comment?.parent }
                } else {
                    return
                }
            }
            
            isHidden = comment?.isHidden ?? false
            isCollapsed = comment?.isCollapsed ?? false
        } while isHidden || isCollapsed
    }
    
    func searchInThread(_ text: String) {
        Task {
            var results = [Int]()
            let text = text.trimmingCharacters(in: .whitespaces)
            let isByOpConditionSatisfied: SearchConditionTester = isByOpSelected ? { $0.by.orEmpty.isNotEmpty && $0.by == self.item?.by.orEmpty } : { _ in true }
            let isNewConditionSatisfied: SearchConditionTester = isNewSelected ? { $0.isNew ?? false } : { _ in true }
            let isSearchQueryHit: SearchConditionTester = text.isEmpty ? { _ in self.isNewSelected || self.isByOpSelected } : { $0.text.orEmpty.localizedCaseInsensitiveContains(text) || $0.by.orEmpty.lowercased().contains(text.lowercased()) }
            for index in 0..<comments.count {
                let comment = comments[index]
                if isByOpConditionSatisfied(comment) && isNewConditionSatisfied(comment) && isSearchQueryHit(comment) {
                    results.append(index)
                }
            }
            
            await MainActor.run {
                withAnimation {
                    self.searchResults = results
                    self.inThreadSearchQuery = text
                }
            }
        }
    }
    
    func translate() {
        guard item != nil else { return }
        translationStatus = .inProgress
        targetLanguage = SettingsViewModel.shared.translationTarget
        guard let translator = CommentTranslator(targetLanguage: targetLanguage) else { return }
        factory = .init(processors: [
            translator,
            MarkdownParser(language: targetLanguage)
        ])
        buffer = comments
        streamTask = Task {
            for await entry in factory.process(buffer) {
                let index = entry.0
                let currentComment = comments[index]
                let comment = entry.1.copyWith(isCollapsed: currentComment.isCollapsed, isHidden: currentComment.isHidden)
                await MainActor.run {
                    withAnimation {
                        comments[index] = comment
                    }
                }
            }
            await MainActor.run {
                withAnimation {
                    translationStatus = .completed
                }
            }
        }
    }
    
    func untranslate() {
        guard item != nil else { return }
        targetLanguage = .englishUS
        factory = .init(processors: [
            MarkdownParser(language: .englishUS)
        ])
        let buffer = buffer
        streamTask = Task {
            for await entry in factory.process(buffer) {
                let index = entry.0
                let currentComment = comments[index]
                let comment = entry.1.copyWith(isCollapsed: currentComment.isCollapsed, isHidden: currentComment.isHidden)
                await MainActor.run {
                    withAnimation {
                        comments[index] = comment
                    }
                }
            }
            await MainActor.run {
                withAnimation {
                    translationStatus = .completed
                }
            }
        }
    }
    
    deinit {
        streamTask?.cancel()
        DispatchQueue.main.async {
            HapticsManager.shared.stop()
        }
    }
}
