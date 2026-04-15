import SwiftUI
import HackerNewsKit

struct AuthButton: View {
    @EnvironmentObject private var auth: Authentication
    
    @Binding var isLoginDialogPresented: Bool
    
    var body: some View {
        if auth.loggedIn, let username = auth.username {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                Router.shared.to(.profile(username))
            } label: {
                Label(auth.username.orEmpty, systemImage: "person.fill")
                    .foregroundStyle(.foreground.opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
            }
            .tint(.accent.opacity(0.6))
            .buttonStyle(.glassProminent)
            .padding(.leading, 12)
        } else {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                isLoginDialogPresented = true
            } label: {
                Label(Action.login.label, systemImage: Action.login.icon)
                    .foregroundStyle(.foreground.opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
            }
            .tint(.accent.opacity(0.6))
            .buttonStyle(.glassProminent)
            .padding(.leading, 12)
        }
    }
}
