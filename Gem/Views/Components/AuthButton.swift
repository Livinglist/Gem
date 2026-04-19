import SwiftUI
import HackerNewsKit

struct AuthButton: View {
    @Environment(Authentication.self) var auth
    
    @Binding var isLoginDialogPresented: Bool
    @State var isProfileSheetPresented: Bool = false
    
    var body: some View {
        if auth.loggedIn, let username = auth.username {
            Button {
                isProfileSheetPresented = true
            } label: {
                Label(auth.username.orEmpty, systemImage: "person.fill")
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
            }
            .tint(.accent.opacity(0.8))
            .buttonStyle(.glassProminent)
            .padding(.leading, 12)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: isProfileSheetPresented)
            .sheet(isPresented: $isProfileSheetPresented) {
                NavigationStack {
                    Profile(id: username)
                        .toolbar {
                            ToolbarItem {
                                Button(role: .close) {
                                    isProfileSheetPresented = false
                                }
                            }
                        }
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
