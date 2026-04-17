import SwiftUI
import HackerNewsKit

struct CommentTextView: View {
    let comment: Comment
    
    var isBlocked: Bool {
        if let authorId = comment.by {
            return SettingsStore.shared.blocklist.contains(authorId)
        }
        return false
    }
    
    var body: some View {
        if isBlocked {
            Text("blocked")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.top, 6)
        } else if comment.text.isNotNullOrEmpty {
            Text(comment.text.orEmpty.markdowned)
                .font(.body)
                .textSelection(.enabled)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding([.leading, .bottom], 4)
                .id(comment.id)
        } else {
            Text("deleted")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.top, 6)
        }
    }
}
