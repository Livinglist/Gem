import SwiftData
import HackerNewsKit

@Model
class StoryModel {
    @Attribute(.unique) var itemId: Int
    var story: Story
    
    init(story: Story) {
        self.itemId = story.id
        self.story = story
    }
}
