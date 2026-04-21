import Foundation
import SwiftUI
import Combine
import HackerNewsKit

struct Submissions: View {
    @State var vm: SubmissionsViewModel = .init()
    @StateObject var debounceObject: DebounceObject = .init()
    @State private var actionPerformed: Action = .none
    
    let ids: [Int]
    
    var body: some View {
        List {
            ForEach(vm.submitted, id: \.self.id) { item in
                ItemRow(item: item,actionPerformed: $actionPerformed)
                .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                .listRowSeparator(.hidden)
                .onAppear {
                    vm.onItemRowAppear(item)
                }
            }
        }
        .listStyle(.plain)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Submissions")
        .onAppear {
            if vm.status == .idle {
                Task {
                    await vm.fetchSubmissions(ids: ids)
                }
            }
        }
        .withToast(actionPerformed: $actionPerformed)
    }
}
