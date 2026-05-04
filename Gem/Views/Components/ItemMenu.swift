import SwiftUI
import HackerNewsKit

extension Label where Title == Text, Icon == Image {
    init(_ action: Action) {
        self.init(action.label, systemImage: action.icon)
    }
}

struct ItemMenu: View {
    let auth = AuthenticationManager.shared
    let item: any Item
    let showViewInSeperateThreadOption: Bool
    let showTranslation: Bool
    @Binding var actionPerformed: Action
    @Binding var activeURL: IdentifiableURL?
    @Binding var isFlagDialogPresented: Bool
    @Binding var isReplySheetPresented: Bool
    @Binding var isTranslationPresented: Bool
    
    var body: some View {
        VStack {
            ControlGroup {
                DownvoteButton(id: item.id, actionPerformed: $actionPerformed)
                UpvoteButton(id: item.id, actionPerformed: $actionPerformed)
            }
            
            ControlGroup {
                FavButton(item: item, actionPerformed: $actionPerformed)
                PinButton(item: item, actionPerformed: $actionPerformed)
                if item is Comment,
                   let user = auth.user,
                   user.id.orEmpty.isNotEmpty, user.id == item.by {
                    Button {
                        onReplyTap(item: item)
                    } label: {
                        Label(.edit)
                    }
                } else {
                    Button {
                        onReplyTap(item: item)
                    } label: {
                        Label(.reply)
                    }
                    .disabled(!auth.loggedIn || item.isJob)
                }
            }
            Divider()
            FlagButton(id: item.id, showFlagDialog: $isFlagDialogPresented)
            Divider()
            ShareMenu(item: item)
            if let text = item.text, text.isNotEmpty {
                CopyButton(text: text, actionPerformed: $actionPerformed)
                if showTranslation {
                    Button {
                        isTranslationPresented = true
                    } label: {
                        Label("Translate", systemImage: "globe")
                    }
                }
            }
            Divider()
            Button {
                onViewOnHackerNewsTap(item: item)
            } label: {
                Label("View in Safari", systemImage: "safari")
            }
            if showViewInSeperateThreadOption {
                Button {
                    Router.shared.to(item)
                } label: {
                    Label("View in Separate Thread", systemImage: "arrow.turn.up.right")
                }
            }
        }
    }
    
    private func flag() {
        let id = item.id
        Task {
            let res = await auth.flag(id)
            
            if res {
                actionPerformed = .flag
            } else {
                actionPerformed = .failure
            }
        }
    }
    
    /// Show the `item`  inside a web view sheet if there is no web view sheet being displayed,
    /// otherwise, show the web view inside a new screen.
    private func onViewOnHackerNewsTap(item: any Item) {
        if let url = URL(string: item.itemUrl) {
            if activeURL != nil {
                Router.shared.to(.url(url))
            } else {
                activeURL = IdentifiableURL(url: url)
            }
        }
    }
    
    /// Display reply view inside a sheet if there is no web view sheet being displayed,
    /// otherwise, display the reply view in a new screen.
    private func onReplyTap(item: any Item) {
        if activeURL != nil {
            if let cmt = item as? Comment {
                Router.shared.to(.replyComment(cmt))
            } else if let story = item as? Story {
                Router.shared.to(.replyStory(story))
            }
        } else {
            isReplySheetPresented = true
        }
    }
}
