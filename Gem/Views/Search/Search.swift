import Foundation
import SwiftUI
import Combine
import HackerNewsKit

struct Search: View {
    @StateObject private var searchStore: SearchStore = .init()
    @StateObject private var debounceObject: DebounceObject = .init()
    @State private var actionPerformed: Action = .none
    @State private var startDate: Date = .init()
    @State private var endDate: Date = .init()
    
    var body: some View {
        List {
            HStack {
                Chip(selected: searchStore.params.sorted, label: "sorted") {
                    searchStore.onSortTap()
                }
                Chip(selected: searchStore.contains(.comment), label: "comment") {
                    searchStore.onTap(filter: .comment)
                }
                Chip(selected: searchStore.contains(.story), label: "story") {
                    searchStore.onTap(filter: .story)
                }
                Chip(selected: searchStore.containsDateRange, label: "date") {
                    searchStore.onDateRangeToggle(.dateRange(startDate, endDate))
                }
            }
            .listRowSeparator(.hidden)
            if searchStore.containsDateRange {
                VStack {
                    DatePicker(selection: $startDate, in: ...Date(), displayedComponents: [.date]) {
                        Text("from")
                    }
                    DatePicker(selection: $endDate, in: ...Date(), displayedComponents: [.date]) {
                        Text("to")
                    }
                }
                .listRowSeparator(.hidden)
            }
            ForEach(searchStore.results, id: \.self.id) { item in
                ItemRow(item: item, actionPerformed: $actionPerformed)
                .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                .listRowSeparator(.hidden)
                .onAppear {
                    searchStore.onItemRowAppear(item)
                }
            }
        }
        .listStyle(.plain)
        .searchable(text: $debounceObject.text, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search Hacker News")
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Search")
        .withToast(actionPerformed: $actionPerformed)
        .onChange(of: debounceObject.debouncedText) { _, text in
            if text.isEmpty { return }
            searchStore.onQueryUpdate(text)
        }
        .onChange(of: startDate) { _, _ in
            searchStore.onDateRangeUpdate(.dateRange(startDate, endDate))
        }.onChange(of: endDate) { _, date in
            searchStore.onDateRangeUpdate(.dateRange(startDate, endDate))
        }
    }
}
