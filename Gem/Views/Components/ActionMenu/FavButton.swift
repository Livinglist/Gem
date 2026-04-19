import SwiftUI
import HackerNewsKit

struct FavButton: View {
    @Environment(Authentication.self) var auth
    let vm = FavoritesViewModel.shared
    
    let item: any Item
    let actionPerformed: Binding<Action>
    
    var body: some View {
        Button {
            onFavorite()
        } label: {
            if vm.has(item) {
                Label(Action.unfavorite.label, systemImage: Action.unfavorite.icon)
            } else {
                Label(Action.favorite.label, systemImage: Action.favorite.icon)
            }
        }
        .disabled(!auth.loggedIn)
    }
    
    private func onFavorite() {
        let isFav = vm.has(item)
        if isFav {
            actionPerformed.wrappedValue = .unfavorite
        } else {
            actionPerformed.wrappedValue = .favorite
        }
        vm.onFavButtonTapped(item)
    }
}
