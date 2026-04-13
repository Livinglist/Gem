import SwiftUI

struct PinButton: View {
    @ObservedObject private var settings: SettingsStore = .shared
    
    let id: Int
    let actionPerformed: Binding<Action>
    
    var body: some View {
        Button {
            onPin()
        } label: {
            if settings.pinList.contains(id) {
                Label(Action.unpin.label, systemImage: Action.unpin.icon)
            } else {
                Label(Action.pin.label, systemImage: Action.pin.icon)
            }
        }
    }
    
    private func onPin() {
        let isPinned = settings.pinList.contains(id)
        if isPinned {
            actionPerformed.wrappedValue = .unpin
        } else {
            actionPerformed.wrappedValue = .pin
        }
        settings.onPinToggle(id)
    }
}
