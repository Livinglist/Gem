import SwiftData
import HackerNewsKit

@Model
class StoryModel {
    var story: Story
    
    init(story: Story) {
        self.story = story
    }
}
