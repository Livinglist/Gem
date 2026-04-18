import SwiftUI
import SwiftData
import HackerNewsKit
import Combine

struct RecentsView: View {
    private var viewModel: RecentsViewModel = .shared
    let onDismiss: (MenuItem?) -> Void
    
    public init(onDismiss: @escaping (MenuItem?) -> Void) {
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text("Recents")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.bottom, 12)
            ForEach(viewModel.stories) { model in
                Text(model.story.title.orEmpty)
                    .foregroundStyle(.foreground.opacity(0.9))
                    .lineLimit(1)
                    .padding(.bottom, 20)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onDismiss(nil)
                        Router.shared.to(model.story)
                    }
            }
        }
        .padding(.bottom, 100)
    }
}
