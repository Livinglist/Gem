import SwiftUI
import WebKit
import HackerNewsKit

struct CommentTile: View {
    @Environment(Authentication.self) var auth
    var vm: ThreadViewModel
    @State private var activeURL: IdentifiableURL?
    @State private var isSafariSheetPresented: Bool = .init()
    @State private var isReplySheetPresented: Bool = .init()
    @State private var isFlagDialogPresented: Bool = .init()
    var settings: SettingsViewModel = .shared
    
    let level: Int
    let comment: Comment
    let allowActions: Bool
    let showLevelIndent: Bool
    @Binding var actionPerformed: Action
    
    var index: Int {
        vm.comments.firstIndex(of: comment) ?? 0
    }
    
    init(comment: Comment,
         vm: ThreadViewModel,
         actionPerformed: Binding<Action>? = nil,
         allowActions: Bool = true,
         showLevelIndent: Bool = true) {
        self.level = comment.level ?? 0
        self.comment = comment
        self.vm = vm
        self._actionPerformed = actionPerformed ?? Binding<Action>(projectedValue: .constant(.none))
        self.allowActions = allowActions
        self.showLevelIndent = showLevelIndent
    }
    
    var isCollapsed: Bool {
        comment.isCollapsed ?? false
    }
    
    var isHidden: Bool {
        comment.isHidden ?? false
    }
    
    var body: some View {
        mainView
            .if(showLevelIndent && level > 0) { view -> AnyView in
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
            .sheet(item: $activeURL) { url in
                SafariView(url: url.url)
            }
            .sheet(isPresented: $isReplySheetPresented) {
                NavigationStack {
                    ReplyView(actionPerformed: $actionPerformed,
                              replyingTo: comment,
                              draggable: true
                    )
                }
            }
            .confirmationDialog("Are you sure?", isPresented: $isFlagDialogPresented) {
                Button("Flag", role: .destructive) {
                    onFlagTap()
                }
            } message: {
                Text("Flag this comment by \(comment.by.orEmpty)?")
            }
    }
    
    @ViewBuilder
    var mainView: some View {
        VStack(alignment: .leading, spacing: 0) {
            if allowActions && isHidden {
                EmptyView()
            } else {
                VStack(spacing: 0) {
                    NameRowView(item: comment,
                                isOP: comment.by == vm.item?.by,
                                isRoot: false,
                                index: index).padding(.bottom, 4)
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
                                        vm.collapse(cmt: comment)
                                    }
                                }
                            }
                    }
                    if vm.loadingItemId == comment.id {
                        ASCIISpinner(size: 24)
                            .padding(.top, 16)
                            .padding(.bottom, 8)
                    } else if !vm.isRecursivelyFetching && !vm.loadedCommentIds.contains(comment.id ) && !isCollapsed && comment.kids.isNotNullOrEmpty {
                        Button {
                            HapticFeedbackService.shared.light()
                            
                            Task {
                                await vm.loadKids(of: comment)
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
                    ItemMenu(item: comment,
                             showViewInSeperateThreadOption: true,
                             actionPerformed: $actionPerformed,
                             activeURL: $activeURL,
                             isFlagDialogPresented: $isFlagDialogPresented,
                             isReplySheetPresented: $isReplySheetPresented)
                }
                preview: {
                    CommentTile(comment: comment, vm: vm, showLevelIndent: false)
                        .padding(6)
                        .frame(width: 360, height: 150, alignment: .topLeading)
                        .environment(auth)
                }
                .onTapGesture {
                    if isCollapsed {
                        HapticFeedbackService.shared.ultralight()
                        withAnimation {
                            vm.uncollapse(cmt: comment)
                        }
                    }
                }
                Spacer()
            }
        }
        .frame(alignment: .leading)
        .padding(.leading, 6)
    }
    
    private func onFlagTap() {
        Task {
            let res = await auth.flag(comment.id)
            
            if res {
                actionPerformed = .flag
            } else {
                actionPerformed = .failure
            }
        }
    }
}
