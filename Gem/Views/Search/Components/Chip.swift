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
            .tint(.purple)
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.mini)
        } else {
            Button {
                onTap()
            } label: {
                Text(label)
            }
            .tint(.purple)
            .buttonStyle(.bordered)
            .buttonBorderShape(.capsule)
            .controlSize(.mini)
        }
    }
}
