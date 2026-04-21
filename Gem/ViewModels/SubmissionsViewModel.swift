import Combine
import SwiftUI
import HackerNewsKit

extension Submissions {
    @MainActor
    @Observable class SubmissionsViewModel {
        var submitted: [any Item] = .init()
        var status: Status = .idle
        
        private var currentPage: Int = 0
        private let pageSize: Int = 10
        var ids: [Int] = .init()
        
        func fetchSubmissions(ids: [Int]) async {
            self.ids = ids
            self.status = .inProgress
            
            let startIndex = min(currentPage * pageSize, ids.count)
            let endIndex = min(startIndex + pageSize, ids.count)
            let items = await StoryRepository.shared.fetchItems(ids: Array(ids[startIndex..<endIndex]))
            
            withAnimation {
                self.status = .completed
                self.submitted.append(contentsOf: items)
            }
        }
        
        func loadMore() async {
            if submitted.count == ids.count {
                return
            }
            
            self.status = .inProgress
            
            currentPage = currentPage + 1
            
            let startIndex = min(currentPage * pageSize, ids.count)
            let endIndex = min(startIndex + pageSize, ids.count)
            let items = await StoryRepository.shared.fetchItems(ids: Array(ids[startIndex..<endIndex]))
            
            withAnimation {
                self.status = .completed
                self.submitted.append(contentsOf: items)
            }
        }
        
        func onItemRowAppear(_ item: any Item) {
            if let last = submitted.last, last.id == item.id {
                Task {
                    await loadMore()
                }
            }
        }
    }
}
