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
                    await fetchItems()
                }
            }
        }
        
        init() {
            favoritesSubscription = settingsStore.$favList.sink(receiveValue: { ids in
                self.favIds = Array<Int>(ids.reversed())
            })
        }
        
        func fetchItems() async {
            self.currentPage = 0
            let range = 0..<min(pageSize, favIds.count)
            let items = await StoryRepository.shared.fetchItems(ids: Array(favIds[range]))
            
            DispatchQueue.main.async {
                withAnimation {
                    self.status = .completed
                    self.items = items
                }
            }
        }
        
        func refresh() async -> Void {
            await fetchItems()
        }
        
        func loadMore() async {
            if items.count == favIds.count {
                return
            }
            
            currentPage = currentPage + 1
            
            let startIndex = min(currentPage * pageSize, favIds.count)
            let endIndex = min(startIndex + pageSize, favIds.count)
            let items = await StoryRepository.shared.fetchItems(ids: Array(favIds[startIndex..<endIndex]))
            
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
