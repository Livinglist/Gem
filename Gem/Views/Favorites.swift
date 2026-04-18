import SwiftUI
import HackerNewsKit

struct Favorites: View {
    @State private var vm = FavoritesViewModel.shared
    @State private var actionPerformed: Action = .none
    private let settings: SettingsStore = .shared
    
    var body: some View {
        if !Authentication.shared.loggedIn {
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    Text("You will be able to view your favorites after login.")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 48)
                }
                Spacer()
            }
            .frame(height: 200)
            .listRowSeparator(.hidden)
        }
        List {
            Picker("", selection: $vm.selectedType) {
                ForEach(ItemType.allCases, id: \.self) { type in
                    Text(type.label)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .listRowSeparator(.hidden)
            if vm.selectedType == .story {
                ForEach(vm.stories, id: \.self.id) { item in
                    ItemRow(item: item, actionPerformed: $actionPerformed)
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .listRowSeparator(.hidden)
                    .onAppear {
                        if item.id == vm.stories.last?.id {
                            Task {
                                await vm.loadMore()
                            }
                        }
                    }
                }
            } else {
                ForEach(vm.comments, id: \.self.id) { item in
                    ItemRow(item: item, actionPerformed: $actionPerformed)
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .listRowSeparator(.hidden)
                    .onAppear {
                        if item.id == vm.comments.last?.id {
                            Task {
                                await vm.loadMore()
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(Text("Favorites"))
        .listStyle(.plain)
        .refreshable {
            Task {
                await vm.refresh()
            }
        }
    }
}
