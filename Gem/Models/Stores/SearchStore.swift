import SwiftUI
import HackerNewsKit

extension Search {
    @MainActor
    class SearchStore: ObservableObject {
        @Published var results: [any Item] = .init()
        @Published var status: Status = .idle
        @Published var params: SearchParams = .init(page: 0, query: .init(), sorted: .init(), filters: Set<SearchFilter>()) {
            didSet {
                if params.query.isNotEmpty {
                    Task {
                        await search(isLoadingMore: params.page != 0)
                    }
                }
            }
        }
        
        var containsDateRange: Bool {
            return params.filters.contains(where: { filter in
                if case .dateRange(_, _) = filter {
                    return true
                }
                return false
            })
        }
        
        var currentDateRange: SearchFilter? {
            for filter in params.filters {
                if case .dateRange(_, _) = filter {
                    return filter
                }
            }
            return nil
        }
        
        func onQueryUpdate(_ query: String) {
            withAnimation {
                self.params = params.copyWith(page: 0, query: query)
            }
        }
        
        func onTap(filter: SearchFilter) {
            var updatedFilters = Set(params.filters)
            
            if updatedFilters.contains(filter) {
                updatedFilters.remove(filter)
            } else {
                updatedFilters.insert(filter)
            }
   
            withAnimation {
                self.params = params.copyWith(page: 0, filters: updatedFilters)
            }
        }
        
        func onSortTap() {
            self.params = params.copyWith(page: 0, sorted: !(params.sorted))
        }
        
        func onDateRangeToggle(_ filter: SearchFilter) {
            var updatedFilters = Set(params.filters)
            
            if let currentDateRangeFilter = currentDateRange {
                updatedFilters.remove(currentDateRangeFilter)
            } else {
                updatedFilters.insert(filter)
            }
            
            withAnimation {
                self.params = params.copyWith(page: 0, filters: updatedFilters)
            }
        }
        
        func onDateRangeUpdate(_ filter: SearchFilter) {
            var updatedFilters = Set(params.filters)
            
            if let currentDateRangeFilter = currentDateRange {
                updatedFilters.remove(currentDateRangeFilter)
            }
            
            if case .dateRange(_, _) = filter {
                updatedFilters.insert(filter)
            }
            
            withAnimation {
                self.params = params.copyWith(page: 0, filters: updatedFilters)
            }
        }
        
        func contains(_ filter: SearchFilter) -> Bool {
            return params.filters.contains(filter)
        }

        func search(isLoadingMore: Bool) async {
            if params.query.isEmpty { return }
            self.status = .inProgress
            var results = [any Item]()
            
            if isLoadingMore {
                results = .init(self.results)
            }
            
            await SearchRepository.shared.search(params: params) { item in
                results.append(item)
            }

            withAnimation {
                self.results = results
                self.status = .completed
            }
        }

        func loadMore() async {
            let page = params.page
            let searchParams = params.copyWith(page: page + 1)
            self.params = searchParams
        }

        func onItemRowAppear(_ item: any Item) {
            if let last = results.last, last.id == item.id {
                Task {
                    await loadMore()
                }
            }
        }
    }
}
