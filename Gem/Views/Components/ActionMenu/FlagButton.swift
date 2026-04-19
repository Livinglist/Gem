import SwiftUI

struct FlagButton: View {
    @Environment(Authentication.self) var auth
    
    let id: Int
    let showFlagDialog: Binding<Bool>
    
    var body: some View {
        Button {
            onFlag()
        } label: {
            Label("Flag", systemImage: "flag")
        }
        .disabled(!auth.loggedIn)
    }
    
    private func onFlag() {
        showFlagDialog.wrappedValue = true
    }
}
