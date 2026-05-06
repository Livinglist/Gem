import SwiftUI
import HackerNewsKit

struct CommentTextView: View {
    let comment: Comment
    let language: Locale.Language
    let highlightedText: String?
    
    var isBlocked: Bool {
        if let authorId = comment.by {
            return SettingsViewModel.shared.blocklist.contains(authorId)
        }
        return false
    }
    
    var attributedString: AttributedString {
        if let highlightedText {
            return MarkdownParser.shared.markdown(id: comment.id, text: comment.text.orEmpty, highlighting: highlightedText)
        } else {
            return MarkdownParser.getCachedAttributedString(id: comment.id, language: language) ?? MarkdownParser.shared.markdown(id: comment.id, text: comment.text.orEmpty)
        }
    }
    
    var body: some View {
        if isBlocked {
            Text("blocked")
                .font(.footnote)
                .foregroundColor(.gray)
                .padding(.top, 6)
        } else if comment.text.isNotNullOrEmpty {
            HStack {
                Text(attributedString)
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
