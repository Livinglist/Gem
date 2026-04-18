import SwiftData
import SwiftUI
import HackerNewsKit
import Foundation


@Observable
class FavoritesViewModel {
    var stories: [Story] = []
    var comments: [Comment] = []
    var selectedType: ItemType = .story
    var status: Status = .idle
    
    @ObservationIgnored private let modelConfig = ModelConfiguration("FavoritesViewModel")
    @ObservationIgnored private var container: ModelContainer?
    private let repo = StoryRepository.shared
    private let auth = Authentication.shared
    private let pageSize = 30
    private var page = 1
    private var commentsPage = 1
    
    static let shared = FavoritesViewModel()
    
    init() {
        let hasCache = loadFromCache()
        if !hasCache {
            Task(priority: .background) {
                await refresh()
            }
        }
    }
    
    func refresh() async {
        defer {
            status = .completed
        }
        guard !status.isLoading, let username = auth.username, username.isNotEmpty else { return }
        status = .inProgress
        let storyIds = await repo.fetchFavorites(of: username, type: .story)
        let stories = await repo.fetchItems(ids: storyIds).compactMap { $0 as? Story }
        let commentIds = await repo.fetchFavorites(of: username, type: .comment)
        let comments = await repo.fetchComments(ids: commentIds)
        self.page = 1
        self.commentsPage = 1
        withAnimation {
            self.stories = stories
            self.comments = comments
        }
        saveToCache()
    }
    
    private func loadFromCache() -> Bool {
        container = try? ModelContainer(for: FavoritesCollection.self, configurations: modelConfig)
        guard let container else { return false }
        let context = container.mainContext
        let favCollection = FetchDescriptor<FavoritesCollection>()
        let result = try? context.fetch(favCollection).first
        guard let result else { return false }
        let stories = result.stories
        let comments = result.comments
        self.stories = stories
        self.comments = comments
        return true
    }
    
    private func saveToCache() {
        guard !(comments.isEmpty && stories.isEmpty) else { return }
        container = container ?? (try? ModelContainer(for: ItemModel.self, configurations: modelConfig))
        if container == nil { return }
        try? container?.erase()
        container = try? ModelContainer(for: ItemModel.self, configurations: modelConfig)
        guard let container else { return }
        let storiesOnFirstPage = stories[0..<min(pageSize, stories.count)]
        let commentsOnFirstPage = comments[0..<min(pageSize, comments.count)]
        let model = FavoritesCollection(comments: Array(commentsOnFirstPage), stories: Array(storiesOnFirstPage))
        container.mainContext.insert(model)
        try? container.mainContext.save()
    }
    
    func loadMore() async {
        defer {
            status = .completed
        }
        guard !status.isLoading, let username = auth.username, username.isNotEmpty else { return }
        status = .inProgress
        var fethcingPage = 0
        
        if selectedType == .story {
            page = page + 1
            fethcingPage = page
        } else {
            commentsPage = commentsPage + 1
            fethcingPage = commentsPage
        }
        
        let ids = await repo.fetchFavorites(of: username, page: fethcingPage, type: selectedType)
        let items = await repo.fetchItems(ids: ids)
        if selectedType == .story {
            let stories = items.compactMap { $0 as? Story }
            withAnimation {
                self.stories.append(contentsOf: stories)
            }
        } else {
            let comments = items.compactMap { $0 as? Comment }
            withAnimation {
                self.comments.append(contentsOf: comments)
            }
        }
    }
    
    private func remove(_ item: any Item) {
        if let _ = item as? Story {
            stories.removeAll(where: { $0.id == item.id })
        } else {
            comments.removeAll(where: { $0.id == item.id })
        }
    }
    
    private func add(_ item: any Item) {
        if let story = item as? Story {
            stories.insert(story, at: 0)
        } else if let comment = item as? Comment {
            comments.insert(comment, at: 0)
        }
    }
    
    func onFavButtonTapped(_ item: any Item) {
        if let story = item as? Story {
            if stories.contains(where: { $0.id == item.id }) {
                Task {
                    await auth.unfavorite(item.id)
                }
                remove(item)
            } else {
                Task {
                    await auth.favorite(item.id)
                }
                add(item)
            }
        } else {
            if comments.contains(where: { $0.id == item.id }) {
                Task {
                    await auth.unfavorite(item.id)
                }
                remove(item)
            } else {
                Task {
                    await auth.favorite(item.id)
                }
                add(item)
            }
        }

        saveToCache()
    }
    
    func has(_ item: any Item) -> Bool {
        if let story = item as? Story {
            stories.contains(where: { $0.id == item.id })
        } else {
            comments.contains(where: { $0.id == item.id })
        }
    }
    
    func has(_ id: Int) -> Bool {
        stories.contains(where: { $0.id == id }) || comments.contains(where: { $0.id == id })
    }
    
    func reset() {
        page = 1
        commentsPage = 1
        comments.removeAll()
        stories.removeAll()
    }
}
