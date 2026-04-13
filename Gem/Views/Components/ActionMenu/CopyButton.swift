import SwiftUI

struct CopyButton: View {
    let text: String
    let actionPerformed: Binding<Action>
    
    var body: some View {
        Button {
            onCopy()
        } label: {
            Label(Action.copy.label, systemImage: Action.copy.icon)
        }
    }
    
    private func onCopy() {
        UIPasteboard.general.string = text
        actionPerformed.wrappedValue = .copy
    }
}
