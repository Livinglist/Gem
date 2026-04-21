import SwiftUI
import HackerNewsKit

struct CommentTextView: View {
    let comment: Comment
    
    var isBlocked: Bool {
        if let authorId = comment.by {
            return SettingsViewModel.shared.blocklist.contains(authorId)
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
            HStack {
                Text(comment.text.orEmpty.markdowned)
                    .tint(.accent)
                    .font(.body)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
            }
            .contentShape(Rectangle())
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
