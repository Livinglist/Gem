import SwiftData
import HackerNewsKit
import Foundation

@Model
class ItemModel {
    @Attribute(.unique) var itemId: Int
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
    
    init(item: any Item) {
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

nonisolated
enum ItemType: Codable {
    case story, comment
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


@Observable
class PinsViewModel {
    var items: [any Item] = []
    @ObservationIgnored private let modelConfig = ModelConfiguration("PinsViewModel")
    @ObservationIgnored private var container: ModelContainer?
    
    static let shared = PinsViewModel()
    
    init() {
        container = try? ModelContainer(for: ItemModel.self, configurations: modelConfig)
        guard let container else { return }
        let context = container.mainContext
        let recents = FetchDescriptor<ItemModel>()
        let results = try? context.fetch(recents)
        items = results?
            .map { $0.itemType == .story ? Story(fromModel: $0) as any Item : Comment(fromModel: $0) as any Item }
            .reversed() ?? []
    }
    
    func remove(_ item: any Item) {
        guard let container else { return }
        let id = item.id
        try? container.mainContext.delete(model: ItemModel.self, where: #Predicate { $0.itemId == id })
        try? container.mainContext.save()
        items.removeAll(where: { $0.id == item.id })
    }
    
    func add(_ item: any Item) {
        guard let container else { return }
        let itemModel = ItemModel(item: item)
        container.mainContext.insert(itemModel)
        try? container.mainContext.save()
        items.insert(item, at: 0)
    }
    
    func onPinToggle(_ item: any Item) {
        if items.contains(where: { $0.id == item.id }) {
            remove(item)
        } else {
            add(item)
        }
    }
    
    func has(_ item: any Item) -> Bool {
        items.contains(where: { $0.id == item.id })
    }
    
    func removeAll() {
        items.removeAll()
        try? container?.erase()
        container = try? ModelContainer(for: ItemModel.self, configurations: modelConfig)
    }
}
