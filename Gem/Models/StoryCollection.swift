import Foundation
import SwiftData
import HackerNewsKit

@Model
class StoryCollection {
    let storyType: StoryType
    let stories: [Story]
    
    init(_ stories: [Story], storyType: StoryType) {
        self.storyType = storyType
        self.stories = stories
    }
}

