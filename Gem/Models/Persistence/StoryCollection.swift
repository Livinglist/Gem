import Foundation
import SwiftData
import HackerNewsKit

@Model
class StoryCollection {
    var storyType: StoryType
    var stories: [Story]
    
    init(_ stories: [Story], storyType: StoryType) {
        self.storyType = storyType
        self.stories = stories
    }
}

