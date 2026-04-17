import Foundation
import SwiftUI
import Combine
import HackerNewsKit

extension Pins {
    @MainActor
    class PinStore: ObservableObject {
        @Published var pinnedItems: [any Item] = .init()
        @Published var status: Status = .idle
        private let settings: SettingsStore = .shared
        private(set) var pinnedIds: [Int] = [Int]() {
            didSet {
                Task {
                    await fetchPinnedStories()
                }
            }
        }
        private var pinListCancellable: AnyCancellable?
        
        init() {
            pinListCancellable = settings.$pinList.sink(receiveValue: { ids in
                self.pinnedIds = Array<Int>(ids.reversed())
            })
        }
        
        func fetchPinnedStories() async {
            let items = await StoryRepository.shared.fetchItems(ids: pinnedIds)
            
            withAnimation {
                self.status = .completed
                self.pinnedItems = items
            }
        }
    }
}
