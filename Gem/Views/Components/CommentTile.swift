import SwiftUI
import WebKit
import HackerNewsKit

struct CommentTile: View {
    @EnvironmentObject var auth: Authentication
    @ObservedObject var itemStore: ItemStore
    @ObservedObject var settingsStore: SettingsStore = .shared
    let settings: SettingsStore = .shared
    
    let level: Int
    let index: Int
    let comment: Comment
    let allowActions: Bool
    
    init(index: Int,
         comment: Comment,
         itemStore: ItemStore,
         allowActions: Bool = true) {
        self.level = comment.level ?? 0
        self.index = index
        self.comment = comment
        self.itemStore = itemStore
        self.allowActions = allowActions
    }
    
    var isCollapsed: Bool {
        comment.isCollapsed ?? false
    }
    
    var isHidden: Bool {
        comment.isHidden ?? false
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
                .id(comment.id)
        }
    }
    
    @ViewBuilder
    var mainView: some View {
        VStack(alignment: .leading, spacing: 0) {
            if allowActions && isHidden {
                EmptyView()
            } else {
                VStack(spacing: 0) {
                    NameRowView(item: comment, isRoot: false, index: index).padding(.bottom, 4)
                    if allowActions && isCollapsed {
                        Text(comment.text.orEmpty.prefix(100))
                            .lineLimit(1)
                            .font(.body)
                            .foregroundStyle(.foreground.opacity(0.4))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                            .padding(.bottom, 8)
                        Text("Collapsed")
                            .font(.footnote.weight(.bold))
                            .foregroundColor(getColor(level: level))
                    } else {
                        CommentTextView(comment: comment)
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
                            
                            Task {
                                await itemStore.loadKids(of: comment)
                            }
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
                    ItemMenu(item: comment)
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
        }
        .frame(alignment: .leading)
        .padding(.leading, 6)
    }
}
