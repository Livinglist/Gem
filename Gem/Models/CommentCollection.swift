import Foundation
import SwiftData
import HackerNewsKit

@Model
class CommentCollection {
    @Attribute(.unique) let parentId: Int
    let comments: [Comment]
    
    init(_ comments: [Comment], parentId: Int) {
        self.parentId = parentId
        self.comments = comments
    }
}
