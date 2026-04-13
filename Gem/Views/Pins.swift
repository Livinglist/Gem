import SwiftUI

struct Pins: View {
    @StateObject var pinStore: PinStore = .init()
    @State private var actionPerformed: Action = .none
    
    var body: some View {        
        List {
            ForEach(pinStore.pinnedItems, id: \.self.id) { item in
                ItemRow(item: item,
                        isPinnedStory: true,
                        actionPerformed: $actionPerformed)
                .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                .listRowSeparator(.hidden)
            }
        }
        .navigationTitle(Text("Pins"))
        .listStyle(.plain)
        .withToast(actionPerformed: $actionPerformed)
    }
}
