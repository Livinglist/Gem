import SwiftUI
import WebKit
import HackerNewsKit

extension Thread {
    struct CommentTile: View {
        @EnvironmentObject var auth: Authentication
        @ObservedObject var itemStore: ItemStore
        @ObservedObject var settingsStore: SettingsStore = .shared

        let level: Int
        let comment: Comment
        let settings: SettingsStore = .shared
        let onLoadMore: () -> Void
        let onShowHNSheet: () -> Void
        let onShowReplySheet: () -> Void
        let onFlag: () -> Void

        init(comment: Comment,
             itemStore: ItemStore,
             onShowHNSheet: @escaping () -> Void,
             onShowReplySheet: @escaping () -> Void,
             onLoadMore: @escaping () -> Void,
             onFlag: @escaping () -> Void) {
            self.level = comment.level ?? 0
            self.comment = comment
            self.onShowHNSheet = onShowHNSheet
            self.onShowReplySheet = onShowReplySheet
            self.onLoadMore = onLoadMore
            self.onFlag = onFlag
            self.itemStore = itemStore
        }
        
        var isCollapsed: Bool {
            itemStore.collapsed.contains(comment.id)
        }

        var isBlocked: Bool {
            if let authorId = comment.by {
                return SettingsStore.shared.blocklist.contains(authorId)
            }
            return false
        }

        var body: some View {
            if itemStore.hidden.contains(comment.id) {
                EmptyView()
            } else {
                mainView
                    .if(level > 0) { view -> AnyView in
                        var wrappedView = AnyView(view)
                        for i in (1...level).reversed() {
                            wrappedView = AnyView(
                                wrappedView
                                    .overlay(Rectangle().frame(width: 1, height: nil, alignment: .leading)
                                        .foregroundColor(getColor(level: i)), alignment: .leading)
                                    .padding(.leading, 6)
                                
                            )
                        }
                        
                        return AnyView(wrappedView)
                    }
            }
        }
        
        @ViewBuilder
        var textView: some View {
            if isBlocked {
                Text("blocked")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.top, 6)
            } else if comment.text.isNotNullOrEmpty {
                Text(comment.text.orEmpty.markdowned)
                    .font(.callout)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 4)
            } else {
                Text("deleted")
                    .font(.footnote)
                    .foregroundColor(.gray)
                    .padding(.top, 6)
            }
        }
        
        @ViewBuilder
        var mainView: some View {
            VStack(alignment: .leading, spacing: 0) {
                VStack(spacing: 0) {
                    nameRow.padding(.bottom, 4)
                    if isCollapsed {
                        Text("Collapsed")
                            .font(.footnote.weight(.bold))
                            .foregroundColor(getColor(level: level))
                    } else {
                        textView
                            .onTapGesture {
                                if !isCollapsed {
                                    HapticFeedbackService.shared.ultralight()
                                    withAnimation {
                                        itemStore.collapse(cmt: comment)
                                    }
                                }
                            }
                    }
                    if itemStore.loadingItemId == comment.id {
                        LoadingIndicator().padding(.top, 16).padding(.bottom, 8)
                    } else if !itemStore.isRecursivelyFetching && itemStore.loadedCommentIds.contains(comment.id) == false && isCollapsed == false && comment.kids.isNotNullOrEmpty {
                        Button {
                            HapticFeedbackService.shared.light()
                            
                            onLoadMore()
                        } label: {
                            Text("\(comment.kids.countOrZero) \(comment.kids.isMoreThanOne ? "replies" : "reply")")
                                .font(.footnote.weight(.bold))
                                .foregroundColor(getColor(level: level))
                                .frame(width: 140)
                        }
                        .buttonStyle(.bordered)
                        .buttonBorderShape(.capsule)
                        .padding(.top, 6)
                    }
                }
                .padding(EdgeInsets(top: 6, leading: 0, bottom: 0, trailing: 0))
                .background(Color(UIColor.systemBackground))
                .contextMenu {
                    // Wrap these in group cuz there's a limit of 10 items in func params.
                    Group {
                        UpvoteButton(id: comment.id, actionPerformed: $itemStore.actionPerformed)
                        DownvoteButton(id: comment.id, actionPerformed: $itemStore.actionPerformed)
                        FavButton(id: comment.id, actionPerformed: $itemStore.actionPerformed)
                        PinButton(id: comment.id, actionPerformed: $itemStore.actionPerformed)
                    }
                    Button {
                        onShowReplySheet()
                    } label: {
                        Label(Action.reply.label, systemImage: Action.reply.icon)
                    }
                    .disabled(!auth.loggedIn)
                    Divider()
                    Button {
                        onFlag()
                    } label: {
                        Label(Action.flag.label, systemImage: Action.flag.icon)
                    }
                    .disabled(!auth.loggedIn)
                    Divider()
                    ShareMenu(item: comment)
                    CopyButton(text: comment.text.orEmpty, actionPerformed: $itemStore.actionPerformed)
                    Button {
                        onShowHNSheet()
                    } label: {
                        Label("View on Hacker News", systemImage: "safari")
                    }
                }
                .onTapGesture {
                    if isCollapsed {
                        HapticFeedbackService.shared.ultralight()
                        withAnimation {
                            itemStore.uncollapse(cmt: comment)
                        }
                    }
                }
                Spacer()
            }
            .frame(alignment: .leading)
            .padding(.leading, 6)
        }
        
        @ViewBuilder
        var nameRow: some View {
            HStack {
                if let author = comment.by {
                    Button {
                        Router.shared.to(.profile(author))
                    } label: {
                        Text(author)
                            .borderedFootnote()
                            .foregroundColor(getColor(level: level))
                    }
                }

                if let karma = comment.score {
                    Text("\(karma) karma")
                        .borderedFootnote()
                        .foregroundColor(getColor(level: level))
                }
                if let descendants = comment.descendants {
                    Text("\(descendants) cmt\(descendants <= 1 ? "" : "s")")
                        .borderedFootnote()
                        .foregroundColor(getColor(level: level))
                }
                Spacer()
                Text(itemStore.timeDisplay == .timeAgo ? comment.timeAgo : comment.formattedTime)
                    .borderedFootnote()
                    .foregroundColor(getColor(level: level))
                    .padding(.trailing, 2)
                    .onTapGesture {
                        withAnimation {
                            itemStore.timeDisplay.toggle()
                        }
                    }
            }
        }
    }
}
