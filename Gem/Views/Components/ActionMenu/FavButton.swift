import SwiftUI

struct FavButton: View {
    @EnvironmentObject var auth: Authentication
    @ObservedObject private var settings: SettingsStore = .shared
    
    let id: Int
    let actionPerformed: Binding<Action>
    
    var body: some View {
        Button {
            onFavorite()
        } label: {
            if settings.favList.contains(id) {
                Label(Action.unfavorite.label, systemImage: Action.unfavorite.icon)
            } else {
                Label(Action.favorite.label, systemImage: Action.favorite.icon)
            }
        }
    }
    
    private func onFavorite() {
        let isFav = settings.favList.contains(id)
        if isFav {
            Task {
                _ = await auth.unfavorite(id)
                actionPerformed.wrappedValue = .unfavorite
            }
        } else {
            Task {
                _ = await auth.favorite(id)
                actionPerformed.wrappedValue = .favorite
            }
        }
        settings.onFavToggle(id)
    }
}
