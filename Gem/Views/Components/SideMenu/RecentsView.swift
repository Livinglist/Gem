import SwiftUI
import SwiftData
import HackerNewsKit
import Combine

@Observable class RecentsViewViewModel {
    var stories: [StoryModel] = []
    @ObservationIgnored private let modelConfig = ModelConfiguration("RecentsViewViewModel")
    @ObservationIgnored private let container: ModelContainer?
    
    static let shared = RecentsViewViewModel()
    
    init() {
        container = try? ModelContainer(for: StoryModel.self, configurations: modelConfig)
        guard let container else { return }
        let context = container.mainContext
        var recents = FetchDescriptor<StoryModel>()
        recents.fetchLimit = 20
        let results = try? context.fetch(recents)
        stories = results?.reversed() ?? []
    }
    
    func insert(story: Story) {
        guard let container else { return }
        let storyModel = StoryModel(story: story)
        container.mainContext.insert(storyModel)
        try? container.mainContext.save()
        stories.insert(storyModel, at: 0)
    }
}

struct RecentsView: View {
    private var viewModel: RecentsViewViewModel = .shared
    let onDismiss: (MenuItem?) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
                Text("Recents")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.bottom)
            
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
    }
}
