import SwiftUI
import HackerNewsKit

struct Pins: View {
    var viewModel: PinsViewModel = .shared
    @State private var actionPerformed: Action = .none
    @State private var isRemoveAllPinsConfirmationAlertPresented = false
    
    var body: some View {        
        List {
            ForEach(viewModel.items, id: \.self.id) { item in
                ItemRow(item: item,
                        isPinnedStory: true,
                        actionPerformed: $actionPerformed)
                .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                .listRowSeparator(.hidden)
            }
        }
        .navigationTitle(Text("Pins"))
        .listStyle(.plain)
        .withToast(actionPerformed: $actionPerformed)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isRemoveAllPinsConfirmationAlertPresented = true
                } label: {
                    Label("Remove all pins", systemImage: "trash")
                        .labelStyle(.iconOnly)
                }
                .sensoryFeedback(trigger: isRemoveAllPinsConfirmationAlertPresented) { oldValue, newValue in
                    if newValue {
                        return .impact(flexibility: .soft)
                    }
                    return nil
                }
            }
        }
        .alert("Remove all pins?", isPresented: $isRemoveAllPinsConfirmationAlertPresented) {
            Button(role: .destructive) {
                isRemoveAllPinsConfirmationAlertPresented = false
                PinsViewModel.shared.removeAll()
            } label: {
                Text("Confirm")
            }
        }
        .sensoryFeedback(trigger: viewModel.items.count) {
            .success
        }
    }
}
