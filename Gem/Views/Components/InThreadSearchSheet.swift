import SwiftUI
import HackerNewsKit

extension Thread {
    struct InThreadSearchSheet: View {
        @ObservedObject var debounceObject: DebounceObject
        @Binding var isSearchPresented: Bool
        var vm: ThreadViewModel
        
        @FocusState private var isSearchFocused: Bool
        
        var body: some View {
            ScrollView {
                HStack {
                    Chip(selected: vm.isNewSelected, label: "New") {
                        vm.isNewSelected.toggle()
                    }
                    Chip(selected: vm.isByOpSelected, label: "By OP") {
                        vm.isByOpSelected.toggle()
                    }
                }
                .frame(maxWidth: .infinity)
                VStack(alignment: .leading, spacing: 0) {
                    if vm.searchStatus.isCompleted && vm.searchResults.isEmpty {
                        Text("nothing found...")
                            .font(.callout)
                            .foregroundStyle(.gray)
                            .padding(.top, 200)
                    }
                    ForEach(vm.searchResults, id: \.self) { index in
                        let comment = vm.comments[index]
                        CommentTile(comment: comment,
                                    vm: vm,
                                    highlightedText: vm.inThreadSearchQuery,
                                    allowActions: false,
                                    showLevelIndent: false)
                            .padding(4)
                            .allowsHitTesting(false)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                isSearchPresented = false
                                
                                Task {
                                    await vm.uncollapseRoot(of: index)
                                    
                                    withAnimation {
                                        vm.scrollViewProxy?.scrollTo(comment.id, anchor: .top)
                                    }
                                    
                                    try? await Task.sleep(until: .now + .seconds(1))
                                    
                                    withAnimation {
                                        vm.scrollViewProxy?.scrollTo(comment.id, anchor: .top)
                                    }
                                }
                            }
                            .id(index)
                        if index != vm.searchResults.last {
                            Divider()
                                .padding(.horizontal, 0)
                        }
                    }
                }
            }
            .toolbar(.visible, for: .navigationBar)
            .scrollDismissesKeyboard(.immediately)
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
            .sensoryFeedback(.success, trigger: vm.searchResults)
        }
    }
}
