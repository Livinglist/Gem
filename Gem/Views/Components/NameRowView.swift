import SwiftUI
import HackerNewsKit

struct NameRowView: View {
    @State var timeDisplay: TimeDisplay = .timeAgo
    let item: any Item
    let isOP: Bool
    let isRoot: Bool
    let index: Int?
    
    var body: some View {
        HStack {
            if let author = item.by {
                Button {
                    Router.shared.to(.profile(author))
                } label: {
                    Text(author)
                        .borderedFootnote(backgroundColor: getColor(level: isRoot ? 0 : ((item as? Comment)?.level ?? 0)))
                        .foregroundColor(.black.opacity(0.8))
                }
            }
            if isOP {
                Text(" <- OP")
                    .borderedFootnote()
            }
            Spacer()
            if let karma = item.score {
                Text("\(karma) karma")
                    .borderedFootnote()
            }
            if let descendants = item.descendants {
                Text("\(descendants) cmt\(descendants <= 1 ? "" : "s")")
                    .borderedFootnote()
            }
            if let comment = item as? Comment, comment.isReply ?? false {
                // Wrapped in text so that it has same height as other text elements in the row.
                Text("\(Image(systemName: "arrow.2.squarepath"))")
                    .borderedFootnote()
            }
            Text(timeDisplay == .timeAgo ? item.shortTimeAgo : item.formattedTime)
                .borderedFootnote()
                .onTapGesture {
                    withAnimation {
                        timeDisplay.toggle()
                    }
                }
            if let index {
                Text("#\(index + 1)")
                    .borderedFootnote()
            }
        }
        .padding(.trailing, 8)
    }
}
