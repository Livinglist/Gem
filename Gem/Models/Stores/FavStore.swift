import Foundation
import Combine
import SwiftUI
import HackerNewsKit

extension Favorites {
    @MainActor
    class FavStore: ObservableObject {
        @Published var items: [any Item] = .init()
        @Published var status: Status = .idle
        
        private let settingsStore: SettingsStore = .shared
        private let pageSize: Int = 10
        private var currentPage: Int = 0
        private var favoritesSubscription: AnyCancellable?
        private var favIds: [Int] = [Int]() {
            didSet {
                Task {
                    await fetchStories()
                }
            }
        }
        
        init() {
            favoritesSubscription = settingsStore.$favList.sink(receiveValue: { ids in
                self.favIds = Array<Int>(ids.reversed())
            })
        }
        
        func fetchStories() async {
            self.currentPage = 0

            var items = [any Item]()
            let range = 0..<min(pageSize, favIds.count)
            await StoryRepository.shared.fetchItems(ids: Array(favIds[range])) { item in
                items.append(item)
            }
            
            DispatchQueue.main.async {
                withAnimation {
                    self.status = .completed
                    self.items = items
                }
            }
        }
        
        func refresh() async -> Void {
            await fetchStories()
        }
        
        func loadMore() async {
            if items.count == favIds.count {
                return
            }
            
            currentPage = currentPage + 1
            
            let startIndex = min(currentPage * pageSize, favIds.count)
            let endIndex = min(startIndex + pageSize, favIds.count)
            var items = [any Item]()
            
            await StoryRepository.shared.fetchItems(ids: Array(favIds[startIndex..<endIndex])) { item in
                items.append(item)
            }
            
            DispatchQueue.main.async {
                withAnimation {
                    self.status = .completed
                    self.items.append(contentsOf: items)
                }
            }
        }
        
        func onItemRowAppear(_ item: any Item) {
            if let last = items.last, last.id == item.id {
                Task {
                    await loadMore()
                }
            }
        }
    }
}
