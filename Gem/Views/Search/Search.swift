import Foundation
import SwiftUI
import Combine
import HackerNewsKit

struct Search: View {
    @State private var vm: SearchViewModel = .init()
    @StateObject private var debounceObject: DebounceObject = .init()
    @State private var actionPerformed: Action = .none
    @State private var startDate: Date = .init()
    @State private var endDate: Date = .init()
    
    var body: some View {
        List {
            HStack {
                Chip(selected: vm.params.sorted, label: "sorted") {
                    vm.onSortTap()
                }
                .sensoryFeedback(.selection, trigger: vm.params.sorted)
                Chip(selected: vm.contains(.comment), label: "comment") {
                    vm.onTap(filter: .comment)
                }
                .sensoryFeedback(.selection, trigger: vm.contains(.comment))
                Chip(selected: vm.contains(.story), label: "story") {
                    vm.onTap(filter: .story)
                }
                .sensoryFeedback(.selection, trigger: vm.contains(.story))
                Chip(selected: vm.containsDateRange, label: "date") {
                    vm.onDateRangeToggle(.dateRange(startDate, endDate))
                }
                .sensoryFeedback(.selection, trigger: vm.containsDateRange)
            }
            .listRowSeparator(.hidden)
            if vm.containsDateRange {
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
            ForEach(vm.results, id: \.self.id) { item in
                ItemRow(item: item, actionPerformed: $actionPerformed)
                .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                .listRowSeparator(.hidden)
                .onAppear {
                    vm.onItemRowAppear(item)
                }
            }
        }
        .sensoryFeedback(.success, trigger: vm.status) { $1.isCompleted }
        .listStyle(.plain)
        .searchable(text: $debounceObject.text, placement: .toolbar, prompt: "Search Hacker News")
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Search on HN")
        .withToast(actionPerformed: $actionPerformed)
        .onChange(of: debounceObject.debouncedText) { _, text in
            if text.isEmpty { return }
            vm.onQueryUpdate(text)
        }
        .onChange(of: startDate) { _, _ in
            vm.onDateRangeUpdate(.dateRange(startDate, endDate))
        }.onChange(of: endDate) { _, date in
            vm.onDateRangeUpdate(.dateRange(startDate, endDate))
        }
    }
}
