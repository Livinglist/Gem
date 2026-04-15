import SwiftUI
import HackerNewsKit

struct AuthButton: View {
    @EnvironmentObject private var auth: Authentication
    
    @Binding var isLoginDialogPresented: Bool
    @State var isProfileSheetPresented: Bool = false
    
    var body: some View {
        if auth.loggedIn, let username = auth.username {
            Button {
                isProfileSheetPresented = true
            } label: {
                Label(auth.username.orEmpty, systemImage: "person.fill")
                    .foregroundStyle(.foreground.opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
            }
            .tint(.accent.opacity(0.6))
            .buttonStyle(.glassProminent)
            .padding(.leading, 12)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: isProfileSheetPresented)
            .sheet(isPresented: $isProfileSheetPresented) {
                NavigationStack {
                    Profile(id: username)
                        .toolbarRole(.navigationStack)
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
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
                    .foregroundStyle(.foreground.opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 6)
            }
            .sensoryFeedback(.impact(flexibility: .soft), trigger: isLoginDialogPresented)
            .tint(.accent.opacity(0.6))
            .buttonStyle(.glassProminent)
            .padding(.leading, 12)
        }
    }
}
