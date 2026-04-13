import SwiftUI

struct Profile: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var auth: Authentication
    @StateObject var profileStore: ProfileStore = .init()
    @State var isLogoutDialogPresented: Bool = .init()
    @State var isBlockDialogPresented: Bool = .init()
    @State var actionPerformed: Action = .none

    let id: String
    
    var body: some View {
        List {
            if let user = profileStore.user {
                Section {
                    if let about = user.about, about.isNotEmpty {
                        Text(about.markdowned)
                    } else {
                        HStack {
                            Spacer()
                            Text("Nothing here...")
                                .font(.footnote)
                                .foregroundStyle(.gray)
                            Spacer()
                        }
                    }
                } header: {
                    Text("About")
                }
                
                Section {
                    DetailedRow(title: "Created at", detail: user.createdAt.orEmpty)
                    DetailedRow(title: "Karma", detail: String(user.karma.orZero))
                    NavigationLink(value: Destination.submission(profileStore.user?.submitted ?? [Int]()), label: {
                        Text("Submissions")
                    })
                } header: {
                    Text("Stats")
                }
                
                if auth.loggedIn && auth.username == id {
                    Button {
                        isLogoutDialogPresented = true
                    } label: {
                        Label("Log out", systemImage: "rectangle.portrait.and.arrow.forward")
                            .foregroundColor(.red)
                    }
                } else if profileStore.isBlocked {
                    Button {
                        profileStore.unblock()
                        actionPerformed = .unblock
                    } label: {
                        Label("Unblock", systemImage: "eye")
                    }
                } else {
                    Button {
                        isBlockDialogPresented = true
                    } label: {
                        Label("Block", systemImage: "eye.slash")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .navigationTitle("About \(id)")
        .navigationBarTitleDisplayMode(.inline)
        .listStyle(.insetGrouped)
        .onAppear {
            if profileStore.status == .idle {
                Task {
                    await profileStore.fetchUser(id: id)
                }
            }
        }
        .alert("Logout", isPresented: $isLogoutDialogPresented, actions: {
            Button("Log out", role: .destructive, action: {
                HapticFeedbackService.shared.success()
                auth.logOut()
                dismiss()
            })
            Button("Cancel", role: .cancel, action: {})
        }, message: {
            Text("Do you want to log out as \(auth.username.orEmpty)?")
        })
        .confirmationDialog("Are you sure?", isPresented: $isBlockDialogPresented) {
            Button("Block", role: .destructive) {
                profileStore.block()
                actionPerformed = .block
            }
        } message: {
            Text("Block \(id)?")
        }
        .withToast(actionPerformed: $actionPerformed)
    }
}

extension Profile {
    struct DetailedRow: View {
        let title: String
        var detail: String? = nil
        
        var body: some View {
            HStack() {
                Text(title)
                if let detail = detail {
                    Spacer()
                    Text(detail).foregroundColor(Color(.secondaryLabel))
                }
            }
        }
    }
}
