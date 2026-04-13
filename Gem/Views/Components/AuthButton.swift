import SwiftUI
import HackerNewsKit

extension Home {
    struct AuthButton: View {
        @EnvironmentObject private var auth: Authentication
        
        @Binding var isLoginDialogPresented: Bool
        
        var body: some View {
            if auth.loggedIn, let username = auth.username {
                Button {
                    Router.shared.to(.profile(username))
                } label: {
                    Label(auth.username.orEmpty, systemImage: "person.fill")
                }
            } else {
                Button {
                    isLoginDialogPresented = true
                } label: {
                    Label(Action.login.label, systemImage: Action.login.icon)
                }
            }
        }
    }
}
