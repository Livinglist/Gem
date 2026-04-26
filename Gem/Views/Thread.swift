import SwiftUI
import WebKit
import HackerNewsKit
import Translation

struct Thread: View {
    @Environment(Authentication.self) var auth
    @State private var vm: ThreadViewModel
    @StateObject private var debounceObject: DebounceObject = .init()
    @State private var scrollViewProxy: ScrollViewProxy? = nil
    @State private var activeURL: IdentifiableURL? = nil
    @State private var isReplySheetPresented: Bool = .init()
    @State private var isFlagDialogPresented: Bool = .init()
    @State private var isTranslationPresented: Bool = .init()
    @State private var isSearchPresented: Bool = .init()
    @State private var actionPerformed: Action = .none
    
    let settings: SettingsViewModel = .shared
    
    let level: Int
    let item: any Item
    
    init(item: any Item, level: Int = 0) {
        self.level = level
        self.item = item
        self.vm = ThreadViewModel(item)
        
        Task { [self] in
            await self.vm.refresh()
        }
    }
    
    var body: some View {
        mainItemView
            .sensoryFeedback(.impact(flexibility: .solid), trigger: isSearchPresented) { $1 }
            .sensoryFeedback(.success, trigger: vm.translationStatus) { _, status in status == .completed }
            .onChange(of: vm.scrollTo) { _, id in
                if settings.isAutoScrollEnabled, let id, vm.comments.first?.id != id {
                    withAnimation {
                        scrollViewProxy?.scrollTo(id, anchor: .top)
                    }
                    vm.scrollTo = nil
                }
            }
            .withToast(actionPerformed: $actionPerformed)
            .sheet(isPresented: $isSearchPresented) {
                NavigationStack {
                    InThreadSearchSheet(debounceObject: debounceObject,
                                      isSearchPresented: $isSearchPresented,
                                      vm: vm,
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
    }
    
    @ViewBuilder
    var mainItemView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                NameRowView(item: vm.item ?? item,
                            isOP: false,
                            isRoot: true,
                            index: nil)
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
                Divider()
                    .padding(.horizontal)
                if vm.status == .inProgress {
                    ASCIISpinner().padding(.top, 100)
                } else if vm.comments.count > 200 {
                    LazyVStack(spacing: 0) {
                        ForEach(vm.comments, id: \.id) { comment in
                            if comment.isHidden ?? true {
                                EmptyView()
                                    .id(comment.id)
                            } else {
                                CommentTile(comment: comment, vm: vm, actionPerformed: $actionPerformed)
                                    .id(comment.id)
                            }
                        }
                    }
                } else {
                    VStack(spacing: 0) {
                        ForEach(vm.comments, id: \.id) { comment in
                            if comment.isHidden ?? true {
                                EmptyView()
                                    .id(comment.id)
                            } else {
                                CommentTile(comment: comment, vm: vm, actionPerformed: $actionPerformed)
                                    .id(comment.id)
                            }
                        }
                    }
                }
                
                Spacer().frame(height: 60)
                if vm.status == Status.completed {
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
            ToolbarItem(placement: .title) {
                Text("")
            }
            if item is Comment {
                ToolbarItem {
                    Button {
                        Task {
                            await vm.goToParent()
                        }
                    } label: {
                        Image(systemName: "figure.stairs")
                    }
                }
            }
            
            ToolbarSpacer(.fixed)
            
            if settings.isTranslationEnabled {
                ToolbarItem {
                    Button {
                        vm.isTranslationEnabled.toggle()
                    } label: {
                        Image(systemName: "character.bubble")
                            .symbolEffect(.variableColor, isActive: vm.translationStatus.isLoading)
                    }
                    .tint(vm.isTranslationEnabled ? .accent : nil)
                }
                ToolbarSpacer(.fixed)
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
                        if !vm.status.isLoading {
                            let prevState = vm.isRecursivelyFetching
                            withAnimation {
                                vm.isRecursivelyFetching.toggle()
                            }
                            actionPerformed = prevState ? .lazyFetching : .eagerFetching
                            Task { await vm.refresh() }
                        }
                    } label: {
                        Image(systemName: vm.isRecursivelyFetching ? Action.eagerFetching.icon : Action.lazyFetching.icon)
                            .symbolEffect(.bounce, isActive: vm.status.isLoading)
                    }
                }
                Menu {
                    ItemMenu(item: item,
                             showViewInSeperateThreadOption: false,
                             showTranslation: true,
                             actionPerformed: $actionPerformed,
                             activeURL: $activeURL,
                             isFlagDialogPresented: $isFlagDialogPresented,
                             isReplySheetPresented: $isReplySheetPresented,
                             isTranslationPresented: $isTranslationPresented)
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
                .translationPresentation(isPresented: $isTranslationPresented, text: item.text.orEmpty)
            }
        }
        .sensoryFeedback(.success, trigger: vm.status.isCompleted)
        .navigationTitle(item is Story ? item.title.orEmpty : "Comment by \(item.by.orEmpty)")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            Task {
                await vm.refresh()
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
