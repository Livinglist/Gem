import SwiftUI
import WebKit
import HackerNewsKit
import Translation

struct PanelConfig: Identifiable, Equatable {
    let id: Int
}

struct ActivePanelKey: PreferenceKey {
    struct Info: Equatable {
        var frame: CGRect
        var panels: [PanelConfig]
        var dragProgress: CGFloat
        var isSwiping: Bool
    }
    static var defaultValue: Info? = nil
    static func reduce(value: inout Info?, nextValue: () -> Info?) {
        value = nextValue() ?? value
    }
}

struct TimeMachineRow<RowContent: View>: View {
    let panels: [PanelConfig]
    let rowContent: RowContent
    
    @State private var dragProgress: CGFloat = 0
    @State private var lastHapticIndex: Int = -1
    @State private var isSwiping = false
    @State private var isHorizontalDrag = false
    @State private var dragOriginX: CGFloat? = nil
    private let haptic = UIImpactFeedbackGenerator(style: .rigid)
    
    private let panelSize = CGSize(width: 300, height: 180)
    private let depthScale: CGFloat = 0.85   // how much smaller each level gets
    private let depthOpacity: CGFloat = 0.80  // how much more transparent each level gets
    private var dragSensitivity: CGFloat {
        let usableWidth: CGFloat = 320 // conservative screen width budget
        return usableWidth / CGFloat(max(panels.count, 1))
    }
    
    init(panels: [PanelConfig], @ViewBuilder rowContent: () -> RowContent) {
        self.panels = panels
        self.rowContent = rowContent()
    }
    
    // depth: 0 = front, positive = further back, negative = being dismissed
    private func props(for index: Int) -> (scale: CGFloat, opacity: Double) {
        let depth = CGFloat(index) - dragProgress
        
        if depth <= -1 {
            return (0, 0)
        } else if depth < 0 {
            // Front panel swiping away: grows and fades out
            let t = -depth  // 0 → 1
            return (1 + t * 0.3, Double(1 - t))
        } else {
            // In the stack: shrinks and dims the further back
            return (
                pow(depthScale, depth),
                Double(pow(depthOpacity, depth))
            )
        }
    }
    
    private func applyStickiness(_ raw: CGFloat) -> CGFloat {
        let step = floor(raw)
        let t = raw - step
        // Cubic ease-in: stays stuck near 0, then accelerates hard toward next panel
        let smooth = t * t * t
        return step + smooth
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            rowContent
                .frame(maxWidth: .infinity)
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(
                            key: ActivePanelKey.self,
                            value: isSwiping ? ActivePanelKey.Info(
                                frame: geo.frame(in: .named("threadScroll")),
                                panels: panels,
                                dragProgress: dragProgress,
                                isSwiping: isSwiping
                            ) : nil
                        )
                    }
                )
            
            // Invisible right-20% gesture zone
            GeometryReader { geo in
                Color.clear
                    .frame(width: geo.size.width * 0.2)
                    .contentShape(Rectangle())
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 30, coordinateSpace: .local)
                            .onChanged { value in
                                if !isHorizontalDrag && !isSwiping {
                                    guard abs(value.translation.width) > abs(value.translation.height) else { return }
                                    isHorizontalDrag = true
                                }
                                guard isHorizontalDrag, value.translation.width < 0 else { return }
                                
                                if !isSwiping {
                                    isSwiping = true
                                    dragOriginX = value.translation.width  // snapshot where we actually started
                                }
                                
                                let origin = dragOriginX ?? value.translation.width
                                let adjusted = max(-(value.translation.width - origin), 0)
                                let raw = adjusted / dragSensitivity
                                let clamped = min(raw, CGFloat(panels.count - 1))
                                dragProgress = applyStickiness(clamped)
                                
                                let currentIndex = Int(dragProgress)
                                if currentIndex != lastHapticIndex {
                                    haptic.impactOccurred(intensity: 1.0)
                                    lastHapticIndex = currentIndex
                                }
                            }
                            .onEnded { _ in
                                dragOriginX = nil
                                isHorizontalDrag = false
                                lastHapticIndex = -1
                                withAnimation(.spring(duration: 0.45, bounce: 0.2)) {
                                    dragProgress = 0
                                    isSwiping = false
                                }
                            }
                    )
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}

struct Thread: View {
    @Environment(AuthenticationManager.self) var auth
    @AppStorage("hasSeenTimeMachineTutorial") private var hasSeenTutorial = false
    
    @State private var vm: ThreadViewModel
    @StateObject private var debounceObject: DebounceObject = .init()
    @State private var activeURL: IdentifiableURL? = nil
    @State private var isReplySheetPresented: Bool = false
    @State private var isFlagDialogPresented: Bool = false
    @State private var isTranslationPresented: Bool = false
    @State private var isSearchPresented: Bool = false
    @State private var isTutorialVideoPresented = false
    @State private var actionPerformed: Action = .none
    @State private var commentTapped: Comment? = nil
    
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
            .withToast(actionPerformed: $actionPerformed)
            .sheet(isPresented: $isTutorialVideoPresented) {
                TimeMachineTutorialSheet()
                    .presentationBackground(.black)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $isSearchPresented) {
                NavigationStack {
                    InThreadSearchSheet(debounceObject: debounceObject,
                                        isSearchPresented: $isSearchPresented,
                                        vm: vm)
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
            .task(id: commentTapped) {
                if let commentTapped, let isCollapsed = commentTapped.isCollapsed {
                    if isCollapsed {
                        await vm.uncollapse(cmt: commentTapped)
                    } else {
                        await vm.collapse(cmt: commentTapped)
                    }
                    self.commentTapped = nil
                }
            }
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
                RootItemView(item: vm.item ?? item, activeURL: $activeURL)
                Divider()
                    .padding(.horizontal)
                if vm.status == .inProgress {
                    ASCIISpinner().padding(.top, 100)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(vm.comments, id: \.id) { comment in
                            if comment.isHidden ?? true {
                                EmptyView()
                                    .id(comment.id)
                            } else if comment.level == 0 {
                                CommentTile(comment: comment, vm: vm, actionPerformed: $actionPerformed)
                                    .id(comment.id)
                                    .onTapGesture {
                                        commentTapped = comment
                                    }
                            } else {
                                TimeMachineRow(
                                    panels: getAncestors(of: comment)
                                ) {
                                    CommentTile(comment: comment, vm: vm, actionPerformed: $actionPerformed)
                                        .onTapGesture {
                                            commentTapped = comment
                                        }
                                }
                                .id(comment.id)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing),
                                    removal: .move(edge: .trailing)
                                ))
                            }
                        }
                    }
                }
                
                Spacer().frame(height: 60)
            }
            .coordinateSpace(name: "threadScroll")
            .overlayPreferenceValue(ActivePanelKey.self) { value in
                if let value, value.isSwiping {
                    let presence: Double = value.isSwiping ? 0.8 : 0
                    
                    Color.black
                        .opacity(presence)
                        .animation(.easeInOut(duration: 0.2), value: value.isSwiping)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                    
                    GeometryReader { geo in
                        let maxPanelHeight = geo.size.height * 0.8
                        
                        ForEach(value.panels.indices.reversed(), id: \.self) { i in
                            let (scale, opacity) = panelProps(index: i, progress: value.dragProgress)
                            let cid = value.panels[i].id
                            if let comment = vm.comments.first(where: { $0.id == cid }) {
                                CommentTile(
                                    comment: comment,
                                    vm: vm,
                                    allowActions: false,
                                    showLevelIndent: false
                                )
                                .frame(width: geo.size.width)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxHeight: maxPanelHeight, alignment: .top)
                                .clipped()
                                .scaleEffect(scale, anchor: .top)
                                .opacity(opacity)
                                .allowsHitTesting(false)
                            }
                        }
                    }
                }
            }
            .onAppear {
                vm.scrollViewProxy = proxy
            }
        }
        .toolbar {
            ToolbarItem(placement: .title) {
                Text("")
            }
            
            if let comment = vm.item as? Comment {
                ToolbarItem {
                    GoToParentButton(comment: comment)
                }
            }
            
            ToolbarSpacer(.fixed)
            
            if !hasSeenTutorial {
                ToolbarItem {
                    Button {
                        hasSeenTutorial = true
                        isTutorialVideoPresented = true
                    } label: {
                        Image(systemName: "lightbulb.max")
                    }
                }
                ToolbarSpacer(.fixed)
            }
            
            if settings.isTranslationAvailable {
                ToolbarItem {
                    Button {
                        if vm.status.isCompleted {
                            vm.isTranslationEnabled.toggle()
                        }
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
            self.vm.refreshTask = Task {
                await vm.refresh()
            }
        }
        .onDisappear {
            self.vm.cleanUp()
        }
    }
    
    private func getAncestors(of comment: Comment) -> [PanelConfig] {
        var ancestors = [Int]()
        var id = comment.parent
        while id != nil && id != -1 {
            ancestors.append(id!)
            id = (vm.comments.first(where: { $0.id == id })?.parent)
        }
        return ancestors.map { .init(id: $0)}
    }
    
    private func panelProps(index: Int, progress: CGFloat) -> (scale: CGFloat, opacity: Double) {
        let depth = CGFloat(index) - progress
        if depth <= -1 { return (0, 0) }
        if depth < 0 {
            let t = -depth
            return (1 + t * 0.3, Double(1 - t))
        }
        return (pow(0.85, depth), Double(pow(0.80, depth)))
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
