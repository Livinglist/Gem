import SwiftUI

struct Chip: View {
    let selected: Bool
    let label: String
    let onTap: () -> Void
    
    var body: some View {
        if selected {
            Button {
                onTap()
            } label: {
                Text(label)
            }
            .tint(.accent)
            .buttonStyle(.glassProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.regular)
        } else {
            Button {
                onTap()
            } label: {
                Text(label)
            }
            .buttonStyle(.glass)
            .buttonBorderShape(.capsule)
            .controlSize(.regular)
        }
    }
}
