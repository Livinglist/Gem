import SwiftData
import HackerNewsKit

@Model
class ItemModel {
    @Attribute(.unique) var itemId: Int
    var index: Int?
    var parent: Int?
    var title: String?
    var text: String?
    var url: String?
    var type: String?
    var by: String?
    var score: Int?
    var descendants: Int?
    var time: Int
    var kids: [Int]?
    var metadata: String
    var itemType: ItemType
    
    init(item: any Item, index: Int = 0) {
        self.index = index
        self.itemId = item.id
        self.parent = item.parent
        self.title = item.title
        self.text = item.text
        self.url = item.url
        self.type = item.type
        self.by = item.by
        self.score = item.score
        self.descendants = item.descendants
        self.time = item.time
        self.kids = item.kids
        self.metadata = item.metadata
        self.itemType = item is Story ? .story : .comment
    }
}

extension Story {
    init(fromModel model: ItemModel) {
        self.init(id: model.itemId, title: model.title, text: model.text, url: model.url, type: model.type, by: model.by, score: model.score, descendants: model.descendants, time: model.time)
    }
}

extension Comment {
    init(fromModel model: ItemModel) {
        self.init(id: model.itemId, parent: model.parent, text: model.text, by: model.by, time: model.time)
    }
}
