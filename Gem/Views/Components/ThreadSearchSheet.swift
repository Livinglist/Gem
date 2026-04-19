import SwiftUI
import HackerNewsKit

extension Thread {
    struct ThreadSearchSheet: View {
        @ObservedObject var debounceObject: DebounceObject
        @Binding var isSearchPresented: Bool
        var vm: ThreadViewModel
        let scrollViewProxy: ScrollViewProxy?
        
        @FocusState private var isSearchFocused: Bool
        
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(vm.searchResults, id: \.self) { index in
                        let comment = vm.comments[index]
                        CommentTile(comment: comment, vm: vm, allowActions: false, showLevelIndent: false)
                            .padding(4)
                            .allowsHitTesting(false)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                isSearchPresented = false
                                withAnimation {
                                    scrollViewProxy?.scrollTo(comment.id, anchor: .top)
                                }
                            }
                        if index != vm.searchResults.last {
                            Divider()
                                .padding(.horizontal, 0)
                        }
                    }
                }
            }
            .navigationTitle("Search in Thread")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem {
                    Button(role: .close) {
                        isSearchPresented = false
                    }
                }
            }
            .searchable(text: $debounceObject.text, placement: .toolbar, prompt: "Search in Thread")
            .searchFocused($isSearchFocused)
            .onChange(of: debounceObject.debouncedText) { _, text in
                if text.isEmpty { return }
                vm.searchInThread(text)
            }
            .onAppear {
                if vm.searchResults.isEmpty {
                    isSearchFocused = true
                }
            }
        }
    }
}
