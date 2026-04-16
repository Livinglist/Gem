import SwiftData
import Foundation
import HackerNewsKit

@Observable class RecentsViewModel {
    var stories: [StoryModel] = []
    @ObservationIgnored private let modelConfig = ModelConfiguration("RecentsViewModel")
    @ObservationIgnored private let container: ModelContainer?
    
    static let shared = RecentsViewModel()
    
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
        try? container.mainContext.delete(model: StoryModel.self, where: #Predicate { $0.itemId == story.id })
        container.mainContext.insert(storyModel)
        try? container.mainContext.save()
        stories.removeAll(where: { $0.itemId == story.id })
        stories.insert(storyModel, at: 0)
    }
}
