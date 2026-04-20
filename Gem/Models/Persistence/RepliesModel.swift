import SwiftData
import HackerNewsKit

@Model
class RepliesModel {
    var fetchedReplies: [Comment]
    var newReplies: [Comment]
    
    init(fetchedReplies: [Comment], newReplies: [Comment]) {
        self.fetchedReplies = fetchedReplies
        self.newReplies = newReplies
    }
}
