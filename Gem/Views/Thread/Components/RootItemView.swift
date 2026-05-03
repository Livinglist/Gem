import SwiftUI
import HackerNewsKit

extension Thread {
    struct RootItemView: View {
        @Binding var activeURL: IdentifiableURL?
        
        let item: any Item
        
        init(item: any Item, activeURL: Binding<IdentifiableURL?>) {
            self._activeURL = activeURL
            self.item = item
        }
        
        var body: some View {
            if item is Story {
                if let url = URL(string: item.url.orEmpty) {
                    VStack(spacing: 0) {
                        ZStack {
                            LinkPreview(url: url,
                                        title: item.title.orEmpty)
                            .onTapGesture {
                                if activeURL == nil {
                                    activeURL = IdentifiableURL(url: url)
                                } else {
                                    Router.shared.to(.url(url))
                                }
                            }
                        }
                        if item.text.orEmpty.isNotEmpty {
                            Text(item.text.orEmpty.markdowned)
                                .tint(.accent)
                                .font(.body)
                                .padding(.horizontal, 10)
                                .padding(.top, 6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                } else {
                    VStack(spacing: 0) {
                        Text(item.title.orEmpty)
                            .font(.system(.title3, design: .serif))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                        Text(item.text.orEmpty.markdowned)
                            .tint(.accent)
                            .font(.body)
                            .padding(.horizontal, 10)
                            .padding(.top, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else if item is Comment {
                VStack(spacing: 0) {
                    Text(item.text.orEmpty.markdowned)
                        .tint(.accent)
                        .font(.body)
                        .padding(.horizontal, 10)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
