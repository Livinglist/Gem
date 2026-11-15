import SwiftUI
import CoreData
import HackerNewsKit
import StoreKit
import Logging

struct Home: View {
    @Environment(AuthenticationManager.self) var auth
    @Environment(\.requestReview) private var requestReview
    @Bindable private var router: Router = .shared

    @State private var isUrlSheetPresented: Bool = .init()
    @State private var isAbortDownloadAlertPresented: Bool = .init()
    @State private var actionPerformed: Action = .none
    @State private var showSlideOutMenu: Bool = false
    @State private var dragOffset: CGFloat = 0
    @State private var isMenuDragCancelled = false
    @GestureState private var isMenuDragging = false
    @State private var selectedMenuItem: MenuItem = .home
    @State private var url: IdentifiableURL? = nil
    private var storyVM: StoryViewModel = .shared
    private var offlineRepository: OfflineRepository = .shared

    private let settings: SettingsViewModel = .shared
    private let appStoreReviewReuqestTrigger = 10

    var body: some View {
        GeometryReader { geometry in
            // Use the current window, so rotation, multitasking, and folding all
            // adapt without replacing the NavigationStack or its destination state.
            let menuWidth = min(CGFloat(300), max(0, geometry.size.width - 60))
            let hasSidebar = geometry.size.width >= 800
            let offset = hasSidebar ? 0 : (showSlideOutMenu ? menuWidth : 0) + dragOffset
            let progress = menuWidth > 0 ? (offset / menuWidth).clamped(to: 0...1) : 0

            ZStack(alignment: .leading) {
                SideMenu(menuWidth: menuWidth, selectedMenuItem: $selectedMenuItem) { selectedItem in
                    withAnimation(.snappy(duration: 0.25)) {
                        showSlideOutMenu = false
                        dragOffset = 0
                        if let selectedItem {
                            selectedMenuItem = selectedItem
                            router.path = NavigationPath()
                        }
                    }
                }
                .opacity(hasSidebar ? 1 : progress)
                .allowsHitTesting(hasSidebar || showSlideOutMenu)
                .accessibilityHidden(!hasSidebar && !showSlideOutMenu)

                mainContent(hasSidebar: hasSidebar)
                    .clipShape(RoundedRectangle(cornerRadius: hasSidebar ? 0 : 24 * progress))
                    .overlay {
                        if !hasSidebar && progress > 0 {
                            Color.black.opacity(0.1 * progress)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    withAnimation(.snappy(duration: 0.25)) {
                                        showSlideOutMenu = false
                                        dragOffset = 0
                                    }
                                }
                                .accessibilityLabel("Close side menu")
                                .accessibilityAddTraits(.isButton)
                        }
                    }
                    .offset(x: offset)
                    .padding(.leading, hasSidebar ? menuWidth : 0)
            }
            .simultaneousGesture(
                menuDragGesture(menuWidth: menuWidth),
                isEnabled: !hasSidebar && (showSlideOutMenu || router.path.isEmpty)
            )
            .onChange(of: geometry.size) { _, _ in
                // A drag begun at the old width must not displace the resized window.
                isMenuDragCancelled = isMenuDragging
                dragOffset = 0
                showSlideOutMenu = false
            }
            .onChange(of: isMenuDragging) { _, isDragging in
                if !isDragging {
                    isMenuDragCancelled = false
                    dragOffset = 0
                }
            }
        }
        .sensoryFeedback(.impact(flexibility: .solid), trigger: showSlideOutMenu)
        .task(priority: .background) {
            try? await Task.sleep(until: .now + .seconds(2))
            let appOpenCounter = settings.appOpenCounter
            Logger.shared.info("Requesting review counter: \(appOpenCounter)")
            if appOpenCounter == appStoreReviewReuqestTrigger {
                requestReview()
                settings.appOpenCounter = appStoreReviewReuqestTrigger + 1
            } else if appOpenCounter < appStoreReviewReuqestTrigger {
                settings.appOpenCounter = appOpenCounter + 1
            }
        }
    }

    private func menuDragGesture(menuWidth: CGFloat) -> some Gesture {
        DragGesture()
            .updating($isMenuDragging) { _, isDragging, _ in
                isDragging = true
            }
            .onChanged { value in
                guard !isMenuDragCancelled else { return }
                let translation = value.translation
                guard abs(translation.width) > abs(translation.height) else { return }
                guard showSlideOutMenu || value.startLocation.x <= 40 else { return }

                if showSlideOutMenu {
                    dragOffset = translation.width.clamped(to: -menuWidth...0)
                } else {
                    dragOffset = translation.width.clamped(to: 0...menuWidth)
                }
            }
            .onEnded { value in
                guard !isMenuDragCancelled else { return }
                withAnimation(.snappy(duration: 0.25)) {
                    if abs(dragOffset) > menuWidth / 4 {
                        showSlideOutMenu = value.translation.width > 0
                    }
                    dragOffset = 0
                }
            }
    }

    private func mainContent(hasSidebar: Bool) -> some View {
        NavigationStack(path: $router.path) {
            ZStack {
                switch selectedMenuItem {
                case .home: Stories()
                case .pinned: Pins()
                case .favorites: Favorites()
                case .replies: Replies()
                case .search: Search()
                }
            }
            .toolbar {
                if !hasSidebar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            withAnimation(.snappy(duration: 0.25)) {
                                showSlideOutMenu = !showSlideOutMenu
                            }
                        } label: {
                            Label("Side menu", systemImage: "book.pages")
                                .labelStyle(.iconOnly)
                                .foregroundStyle(.foreground)
                                .glassEffect()
                        }
                    }
                }
                if selectedMenuItem == .home {
                    if offlineRepository.isDownloading {
                        ToolbarItem(placement: .topBarTrailing) {
                            Text("\(offlineRepository.completionCount)")
                                .contentTransition(.numericText())
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        DownloadMenu(storyViewModel: storyVM,
                                     offlineRepository: offlineRepository,
                                     isAbortDownloadAlertPresented: $isAbortDownloadAlertPresented)
                    }
                }
            }
            .toolbarTitleDisplayMode(.inline)
            .withToast(actionPerformed: $actionPerformed)
            .alert("Abort Download", isPresented: $isAbortDownloadAlertPresented) {
                Button {
                    offlineRepository.abortDownload()
                } label: {
                    Text("Confirm")
                }
                Button(role: .cancel) {
                    offlineRepository.abortDownload()
                } label: {
                    Text("Confirm")
                }
            }
            .sheet(item: $url) { url in
                SafariView(url: url.url)
            }
            .onOpenURL(perform: { url in
                if let id = url.absoluteString.itemId {
                    Task {
                        let story = await StoryRepository.shared.fetchStory(id)
                        guard let story = story else { return }
                        router.to(story)
                    }
                }
            })
            .onChange(of: offlineRepository.isOfflineReading) {
                Task {
                    await storyVM.fetchStories()
                }
            }
            .environment(\.openURL, OpenURLAction { url in
                if let id = url.absoluteString.itemId {
                    Task {
                        let item = await StoryRepository.shared.fetchItem(id)
                        guard let item = item else {
                            self.url = IdentifiableURL(url: url)
                            return
                        }

                        router.to(item)
                    }
                    return .handled
                } else {
                    self.url = IdentifiableURL(url: url)
                    return .handled
                }
            })
            .navigationDestination(for: Comment.self) { cmt in
                Thread(item: cmt, level: 0)
            }
            .navigationDestination(for: Story.self) { story in
                Thread(item: story, level: 0)
            }
            .navigationDestination(for: Destination.self) { val in val.toView() }
        }
    }
}
