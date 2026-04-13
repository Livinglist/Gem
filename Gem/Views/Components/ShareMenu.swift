import SwiftUI
import HackerNewsKit

struct ShareMenu: View {
    let item: any Item
    
    @ViewBuilder
    var shareLabel: some View {
        Label("Share", systemImage: "square.and.arrow.up")
    }
    
    var body: some View {
        if item.url.orEmpty.isEmpty {
            Button {
                showShareSheet(url: item.itemUrl)
            } label: {
                shareLabel
            }
        } else {
            Menu {
                Button {
                    showShareSheet(url: item.url.orEmpty)
                } label: {
                    Text("Link to story")
                }
                Button {
                    showShareSheet(url: item.itemUrl)
                } label: {
                    Text("Link to HN")
                }
            } label: {
                shareLabel
            }
        }
    }
}
