import SwiftUI
import HackerNewsKit

struct Replies: View {
    @Environment(Authentication.self) private var auth
    @State private var vm = RepliesViewModel.shared
    @State private var actionPerformed: Action = .none
    @State private var isMarkAllAsReadAlertPresented = false
    
    var body: some View {
        List {
            if auth.loggedIn {
                ForEach(vm.fetchedComments, id: \.self.id) { comment in
                    ItemRow(item: comment,
                            isNew: vm.newReplies.contains(comment),
                            actionPerformed: $actionPerformed)
                    .onTapGesture {
                        vm.markAsRead(comment: comment)
                        Router.shared.to(comment)
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .listRowSeparator(.hidden)
                }
            } else {
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        Text("You will be able to view replies to your comments after login.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 48)
                    }
                    Spacer()
                }
                .padding(.top, 200)
                .listRowSeparator(.hidden)
            }
        }
        .navigationTitle(Text("Replies"))
        .listStyle(.plain)
        .refreshable {
            Task {
                await vm.refresh()
            }
        }
        .onChange(of: auth.loggedIn) { _, loggedIn in
            if loggedIn {
                Task {
                    await vm.refresh()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isMarkAllAsReadAlertPresented = true
                } label: {
                    Label("Mark all as read", systemImage: "envelope.open.fill")
                        .labelStyle(.iconOnly)
                }
                .sensoryFeedback(trigger: isMarkAllAsReadAlertPresented) { oldValue, newValue in
                    if newValue {
                        return .impact(flexibility: .soft)
                    }
                    return nil
                }
            }
        }
        .alert("Mark all as read?", isPresented: $isMarkAllAsReadAlertPresented) {
            Button {
                isMarkAllAsReadAlertPresented = false
                vm.markAllAsRead()
            } label: {
                Text("Confirm")
            }
        }
        .sensoryFeedback(trigger: vm.newReplies.count) {
            .success
        }
    }
}
