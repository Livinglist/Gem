import SwiftData

@Model
class ThreadCacheModel {
    @Attribute(.unique) var parentId: Int
    var commentIds: [Int]
    
    init(_ commentIds: [Int], parentId: Int) {
        self.parentId = parentId
        self.commentIds = commentIds
    }
}
