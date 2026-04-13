import SwiftUI

struct Favorites: View {
    @StateObject var favStore: FavStore = .init()
    @State private var actionPerformed: Action = .none
    private let settings: SettingsStore = .shared
    
    var body: some View {
        if settings.favList.isEmpty {
            EmptyView()
        }
        List {
            ForEach(favStore.items, id: \.self.id) { story in
                ItemRow(item: story, actionPerformed: $actionPerformed)
                .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                .listRowSeparator(.hidden)
                .onAppear {
                    favStore.onItemRowAppear(story)
                }
            }
        }
        .navigationTitle(Text("Favorites"))
        .listStyle(.plain)
        .refreshable {
            Task {
                await favStore.refresh()
            }
        }
        .onAppear {
            if favStore.status == Status.idle {
                Task {
                    await favStore.fetchStories()
                }
            }
        }
    }
}
