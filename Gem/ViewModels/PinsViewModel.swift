import SwiftData
import SwiftUI
import HackerNewsKit
import Foundation

@Observable class PinsViewModel {
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
        withAnimation {
            items.removeAll(where: { $0.id == item.id })
        }
    }
    
    func add(_ item: any Item) {
        guard let container else { return }
        let itemModel = ItemModel(item: item)
        container.mainContext.insert(itemModel)
        try? container.mainContext.save()
        withAnimation {
            items.insert(item, at: 0)
        }
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
