import SwiftUI
import HackerNewsKit

extension Thread {
    struct GoToParentButton: View {
        @State var isParentLoading = false
        
        let item: any Item
        
        var body: some View {
            Button {
                isParentLoading = true
                Task {
                    await goToParent()
                }
            } label: {
                Image(systemName: "figure.stairs")
                    .symbolEffect(.pulse, isActive: isParentLoading)
            }
        }
        
        private func goToParent() async {
            guard let parentId = item.parent,
                  let parent = await StoryRepository.shared.fetchItem(parentId)
            else { return }
            isParentLoading = false
            Router.shared.to(parent)
        }
    }
}
