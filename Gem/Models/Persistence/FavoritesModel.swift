import SwiftData
import HackerNewsKit

@Model
class FavoritesCollection {
    var comments: [Comment]
    var stories: [Story]
    
    init(comments: [Comment], stories: [Story]) {
        self.comments = comments
        self.stories = stories
    }
}
