import SwiftUI
import HackerNewsKit

struct NameRowView: View {
    @State var timeDisplay: TimeDisplay = .timeAgo
    let item: any Item
    let isRoot: Bool
    let index: Int?
    
    var body: some View {
        HStack {
            if let author = item.by {
                Button {
                    Router.shared.to(.profile(author))
                } label: {
                    Text(author)
                        .borderedFootnote()
                        .foregroundColor(getColor(level: isRoot ? 0 : ((item as? Comment)?.level ?? 0)))
                }
            }
            if let karma = item.score {
                Text("\(karma) karma")
                    .borderedFootnote()
                    .foregroundColor(getColor())
            }
            if let descendants = item.descendants {
                Text("\(descendants) cmt\(descendants <= 1 ? "" : "s")")
                    .borderedFootnote()
                    .foregroundColor(getColor())
            }
            Spacer()
            Text(timeDisplay == .timeAgo ? item.shortTimeAgo : item.formattedTime)
                .borderedFootnote()
                .padding(.trailing, 2)
                .onTapGesture {
                    withAnimation {
                        timeDisplay.toggle()
                    }
                }
            if let index {
                Text("#\(index + 1)")
                    .borderedFootnote()
                    .padding(.trailing, 2)
            }
        }
    }
}
