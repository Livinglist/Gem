import SwiftUI

struct UpvoteButton: View {
    @EnvironmentObject var auth: Authentication
    
    let id: Int
    let actionPerformed: Binding<Action>
    
    var body: some View {
        Button {
            onUpvote()
        } label: {
            Label(Action.upvote.label, systemImage: Action.upvote.icon)
        }
        .disabled(!auth.loggedIn)
    }
    
    private func onUpvote() {
        Task {
            let res = await auth.upvote(id)
            
            if res {
                actionPerformed.wrappedValue = .upvote
            } else {
                actionPerformed.wrappedValue = .failure
            }
        }
    }
}
