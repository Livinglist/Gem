import SwiftUI
import WebKit
import HackerNewsKit

struct Thread: View {
    @EnvironmentObject private var auth: Authentication
    @StateObject private var itemStore: ItemStore = .init()
    @StateObject private var debounceObject: DebounceObject = .init()
    @State private var scrollViewProxy: ScrollViewProxy? = nil
    @State private var activeURL: IdentifiableURL? = nil
    @State private var isReplySheetPresented: Bool = .init()
    @State private var isFlagDialogPresented: Bool = .init()
    @State private var isSearchPresented: Bool = .init()
    @State private var actionPerformed: Action = .none
    
    let settings: SettingsStore = .shared
    
    let level: Int
    let item: any Item
    
    init(item: any Item, level: Int = 0) {
        self.level = level
        self.item = item
    }
    
    var body: some View {
        mainItemView
            .withToast(actionPerformed: $actionPerformed)
            .sheet(isPresented: $isSearchPresented) {
                NavigationStack {
                    ThreadSearchSheet(debounceObject: debounceObject,
                                      isSearchPresented: $isSearchPresented,
                                      itemStore: itemStore,
                                      scrollViewProxy: scrollViewProxy)
                }
            }
            .sheet(item: $activeURL) { url in
                SafariView(url: url.url, draggable: true)
            }
            .sheet(isPresented: $isReplySheetPresented) {
                NavigationStack {
                    ReplyView(actionPerformed: $actionPerformed,
                              replyingTo: item,
                              draggable: true
                    )
                }
            }
            .environment(\.openURL, OpenURLAction { url in
                if let id = url.absoluteString.itemId {
                    Task {
                        let item = await StoryRepository.shared.fetchItem(id)
                        guard let item = item else {
                            activeURL = IdentifiableURL(url: url)
                            return
                        }
                        Router.shared.to(item)
                    }
                } else {
                    if activeURL != nil {
                        Router.shared.to(.url(url))
                    } else {
                        activeURL = IdentifiableURL(url: url)
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
                    .padding(.top, 6)
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
                    ASCIISpinner().padding(.top, 100)
                } else if itemStore.comments.count > 200 {
                    LazyVStack(spacing: 0) {
                        ForEach(itemStore.comments, id: \.id) { comment in
                            if comment.isHidden ?? true {
                                EmptyView()
                            } else {
                                CommentTile(comment: comment, itemStore: itemStore, actionPerformed: $actionPerformed)
                                    .id(comment.id)
                            }
                        }
                    }
                } else {
                    VStack(spacing: 0) {
                        ForEach(itemStore.comments, id: \.id) { comment in
                            if comment.isHidden ?? true {
                                EmptyView()
                            } else {
                                CommentTile(comment: comment, itemStore: itemStore, actionPerformed: $actionPerformed)
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
                        Image(systemName: "figure.stairs")
                    }
                }
            }
            
            ToolbarSpacer(.fixed)
            
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
                            let prevState = itemStore.isRecursivelyFetching
                            withAnimation {
                                itemStore.isRecursivelyFetching.toggle()
                            }
                            actionPerformed = prevState ? .lazyFetching : .eagerFetching
                            Task { await itemStore.refresh() }
                        }
                    } label: {
                        Image(systemName: itemStore.isRecursivelyFetching ? Action.eagerFetching.icon : Action.lazyFetching.icon)
                            .symbolEffect(.bounce, isActive: itemStore.status.isLoading)
                    }
                }
                Menu {
                    ItemMenu(item: item,
                             actionPerformed: $actionPerformed,
                             activeURL: $activeURL,
                             isFlagDialogPresented: $isFlagDialogPresented,
                             isReplySheetPresented: $isReplySheetPresented)
                } label: {
                    Image(systemName: "ellipsis")
                }
                .confirmationDialog("Are you sure?", isPresented: $isFlagDialogPresented) {
                    Button("Flag", role: .destructive) {
                        onFlagTap()
                    }
                } message: {
                    Text("Flag \"\(item.title.orEmpty)\" by \(item.by.orEmpty)?")
                }
            }
        }
        .sensoryFeedback(.success, trigger: itemStore.status.isCompleted)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            Task {
                await itemStore.refresh()
            }
        }
    }
    
    private func onFlagTap() {
        Task {
            let res = await auth.flag(item.id)
            
            if res {
                actionPerformed = .flag
            } else {
                actionPerformed = .failure
            }
        }
    }
}
