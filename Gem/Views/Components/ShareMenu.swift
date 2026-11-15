import SwiftUI
import HackerNewsKit

struct ShareMenu: View {
    let item: any Item

    @ViewBuilder
    var shareLabel: some View {
        Label("Share", systemImage: "square.and.arrow.up")
    }

    var body: some View {
        if let itemURL = URL(string: item.itemUrl) {
            if let url = item.url, !url.isEmpty,
               let storyURL = URL(string: url), storyURL.scheme != nil {
                Menu {
                    ShareLink(item: storyURL) {
                        Text("Link to story")
                    }
                    ShareLink(item: itemURL) {
                        Text("Link to HN")
                    }
                } label: {
                    shareLabel
                }
            } else {
                ShareLink(item: itemURL) {
                    shareLabel
                }
            }
        }
    }
}
