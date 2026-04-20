import SwiftUI
import HackerNewsKit

struct PinButton: View {
    let item: any Item
    let actionPerformed: Binding<Action>
    var isPinned: Bool {
        PinsViewModel.shared.has(item)
    }
    
    var body: some View {
        Button {
            onPin()
        } label: {
            if isPinned {
                Label(Action.unpin.label, systemImage: Action.unpin.icon)
            } else {
                Label(Action.pin.label, systemImage: Action.pin.icon)
            }
        }
    }
    
    private func onPin() {
        if isPinned {
            actionPerformed.wrappedValue = .unpin
            PinsViewModel.shared.remove(item)
        } else {
            actionPerformed.wrappedValue = .pin
            PinsViewModel.shared.add(item)
        }
    }
}
