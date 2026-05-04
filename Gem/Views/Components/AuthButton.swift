import SwiftUI
import HackerNewsKit

struct AuthButton: View {
    @Environment(AuthenticationManager.self) var auth
    @Bindable var router = Router.shared
    
    @Binding var isLoginDialogPresented: Bool
    
    var body: some View {
        if auth.loggedIn, let username = auth.username {
            Button {
                router.isProfileSheetPresented = true
            } label: {
                Label(auth.username.orEmpty, systemImage: "person.fill")
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
            }
            .tint(.accent.opacity(0.8))
            .buttonStyle(.glassProminent)
            .padding(.leading, 12)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: router.isProfileSheetPresented)
            .sheet(isPresented: $router.isProfileSheetPresented) {
                NavigationStack(path: $router.sheetPath) {
                    Profile(id: username)
                        .toolbar {
                            ToolbarItem {
                                Button(role: .close) {
                                    router.isProfileSheetPresented = false
                                }
                            }
                        }
                        .navigationDestination(for: Comment.self) { cmt in
                            Thread(item: cmt, level: 0)
                        }
                        .navigationDestination(for: Story.self) { story in
                            Thread(item: story, level: 0)
                        }
                        .navigationDestination(for: Destination.self) { val in val.toView() }
                }
            }
        } else {
            Button {
                isLoginDialogPresented = true
            } label: {
                Label(Action.login.label, systemImage: Action.login.icon)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
            }
            .sensoryFeedback(.impact(flexibility: .soft), trigger: isLoginDialogPresented)
            .tint(.accent.opacity(0.8))
            .buttonStyle(.glassProminent)
            .padding(.leading, 12)
        }
    }
}
