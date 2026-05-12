import SwiftUI
import HackerNewsKit

struct BorderedCommentTile: View {
    var vm: ThreadViewModel
    var settings: SettingsViewModel = .shared
    
    let comment: Comment
    let maxHeight: CGFloat
    
    var index: Int {
        vm.comments.firstIndex(of: comment) ?? 0
    }
    
    init(comment: Comment,
         vm: ThreadViewModel,
         maxHeight: CGFloat) {
        self.comment = comment
        self.vm = vm
        self.maxHeight = maxHeight
    }
    
    var isCollapsed: Bool {
        comment.isCollapsed ?? false
    }
    
    var isHidden: Bool {
        comment.isHidden ?? false
    }
    
    var body: some View {
        mainView
            .id(comment.id)
    }
    
    @ViewBuilder
    var mainView: some View {
        VStack(alignment: .leading, spacing: 0) {
            NameRowView(item: comment,
                        isOP: comment.by == vm.item?.by,
                        isRoot: false,
                        index: index).padding(.bottom, 4)
            CommentTextView(comment: comment,
                            language: vm.targetLanguage,
                            highlightedText: nil)
        }
        .frame(maxHeight: maxHeight - 24, alignment: .top)
        .padding(EdgeInsets(top: 6, leading: 6, bottom: 0, trailing: 0))
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.all, 8)
    }
}
