import SwiftUI

struct DownvoteButton: View {
    @Environment(Authentication.self) var auth
    
    let id: Int
    let actionPerformed: Binding<Action>
    
    var body: some View {
        Button {
            onDownvote()
        } label: {
            Label(Action.downvote.label, systemImage: Action.downvote.icon)
        }
        .disabled(!auth.loggedIn)
    }
    
    private func onDownvote() {
        Task {
            let res = await auth.downvote(id)
            
            if res {
                actionPerformed.wrappedValue = .downvote
            } else {
                actionPerformed.wrappedValue = .failure
            }
        }
    }
}
