import SwiftUI
import WebKit
import HackerNewsKit

extension Thread {
    struct ThreadSearchSheet: View {
        @ObservedObject var debounceObject: DebounceObject
        @Binding var isSearchPresented: Bool
        var itemStore: ItemStore
        let scrollViewProxy: ScrollViewProxy?
        
        @FocusState private var isSearchFocused: Bool
        
        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(itemStore.searchResults, id: \.self) { index in
                        let comment = itemStore.comments[index]
                        CommentTile(index: index, comment: comment, itemStore: itemStore, allowActions: false)
                            .padding(4)
                            .allowsHitTesting(false)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                isSearchPresented = false
                                withAnimation {
                                    scrollViewProxy?.scrollTo(comment.id, anchor: .top)
                                }
                            }
                        if index != itemStore.searchResults.last {
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
                itemStore.searchInThread(text)
            }
            .onAppear {
                if itemStore.searchResults.isEmpty {
                    isSearchFocused = true
                }
            }
        }
    }
}

struct Thread: View {
    @EnvironmentObject private var auth: Authentication
    @StateObject private var itemStore: ItemStore = .init()
    @StateObject private var debounceObject: DebounceObject = .init()
    @State private var scrollViewProxy: ScrollViewProxy? = nil
    @State private var isSafariSheetPresented: Bool = .init()
    @State private var isSearchPresented: Bool = .init()
    static private var handledUrl: URL? = nil
    
    let settings: SettingsStore = .shared
    
    let level: Int
    let item: any Item
    
    init(item: any Item, level: Int = 0) {
        self.level = level
        self.item = item
    }
    
    var body: some View {
        mainItemView
            .withToast(actionPerformed: $itemStore.actionPerformed)
            .sheet(isPresented: $isSearchPresented) {
                NavigationStack {
                    ThreadSearchSheet(debounceObject: debounceObject,
                                      isSearchPresented: $isSearchPresented,
                                      itemStore: itemStore,
                                      scrollViewProxy: scrollViewProxy)
                }
            }
            .sheet(isPresented: $isSafariSheetPresented) {
                if let url = Self.handledUrl {
                    SafariView(url: url, draggable: true)
                }
            }
            .environment(\.openURL, OpenURLAction { url in
                if let id = url.absoluteString.itemId {
                    Task {
                        let item = await StoryRepository.shared.fetchItem(id)
                        guard let item = item else {
                            Self.handledUrl = url
                            isSafariSheetPresented = true
                            return
                        }
                        Router.shared.to(item)
                    }
                } else {
                    if isSafariSheetPresented {
                        Router.shared.to(.url(url))
                    } else {
                        Self.handledUrl = url
                        isSafariSheetPresented = true
                    }
                }
                return .handled
            })
            .task {
                if itemStore.item == nil {
                    itemStore.item = item
                    await itemStore.refresh()
                }
            }
    }
    
    @ViewBuilder
    var mainItemView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                NameRowView(item: itemStore.item ?? item, isRoot: true, index: nil)
                    .padding(.leading, 6)
                    .padding(.trailing, 4)
                    .padding(.top, 6)
                if item is Story {
                    if let url = URL(string: item.url.orEmpty) {
                        VStack(spacing: 0) {
                            ZStack {
                                LinkPreview(url: url,
                                            title: item.title.orEmpty)
                                .onTapGesture {
                                    Self.handledUrl = url
                                    isSafariSheetPresented = true
                                }
                            }
                            if item.text.orEmpty.isNotEmpty {
                                Text(item.text.orEmpty.markdowned)
                                    .font(.body)
                                    .padding(.horizontal, 10)
                                    .padding(.top, 6)
                            }
                        }
                    } else {
                        VStack(spacing: 0) {
                            Text(item.title.orEmpty)
                                .font(.system(.title3, design: .serif))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 12)
                            Text(item.text.orEmpty.markdowned)
                                .font(.body)
                                .padding(.horizontal, 10)
                                .padding(.top, 6)
                        }
                        .frame(maxWidth: .infinity)
                    }
                } else if item is Comment {
                    HStack {
                        Text(item.text.orEmpty.markdowned)
                            .font(.body)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 10)
                    }
                    .frame(maxWidth: .infinity)
                }
                Divider()
                    .padding(.horizontal)
                if itemStore.status == .inProgress {
                    LoadingIndicator().padding(.top, 100)
                }
                if itemStore.comments.count > 100 {
                    LazyVStack(spacing: 0) {
                        ForEach(itemStore.comments.indices, id: \.self) { index in
                            let comment = itemStore.comments[index]
                            if comment.isHidden ?? true {
                                EmptyView()
                            } else {
                                CommentTile(index: index, comment: comment, itemStore: itemStore)
                                    .padding(.trailing, 4)
                                    .id(comment.id)
                            }
                        }
                    }
                } else {
                    VStack(spacing: 0) {
                        ForEach(itemStore.comments.indices, id: \.self) { index in
                            let comment = itemStore.comments[index]
                            if comment.isHidden ?? true {
                                EmptyView()
                            } else {
                                CommentTile(index: index, comment: comment, itemStore: itemStore)
                                    .padding(.trailing, 4)
                                    .id(comment.id)
                            }
                        }
                    }
                }
                
                Spacer().frame(height: 60)
                if itemStore.status == Status.completed {
                    Text(Constants.happyFace)
                        .foregroundColor(.gray)
                        .padding(.bottom, 40)
                }
            }
            .onAppear {
                self.scrollViewProxy = proxy
            }
        }
        .toolbar {
            if let item = item as? Comment {
                ToolbarItem {
                    Button {
                        Task {
                            await itemStore.fetchParent(of: item)
                        }
                    } label: {
                        Image(systemName: "backward.circle")
                    }
                }
            }
            
            ToolbarItem {
                Button {
                    isSearchPresented = true
                } label: {
                    Image(systemName: "doc.text.magnifyingglass")
                }
                .accessibilityLabel("Search")
            }
            
            ToolbarSpacer(.fixed)
            
            ToolbarItemGroup {
                if !OfflineRepository.shared.isOfflineReading {
                    Button {
                        if !itemStore.status.isLoading {
                            withAnimation {
                                itemStore.isRecursivelyFetching.toggle()
                            }
                            Task { await itemStore.refresh() }
                        }
                    } label: {
                        Image(systemName: itemStore.isRecursivelyFetching ? Action.lazyFetching.icon : Action.eagerFetching.icon)
                            .if(itemStore.status.isLoading) { view in
                                view.foregroundStyle(.gray.opacity(0.8))
                            }
                    }
                }
                
                Menu {
                    ItemMenu(item: item)
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .overlay {
            if !itemStore.isRecursivelyFetching && itemStore.status.isLoading, let total = item.kids?.count, total != 0 {
                VStack {
                    ProgressView(value: Double(itemStore.comments.count), total: Double(total))
                    Spacer()
                }
            } else {
                EmptyView()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            Task {
                await itemStore.refresh()
            }
        }
    }
}
