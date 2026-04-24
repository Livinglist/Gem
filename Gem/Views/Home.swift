import SwiftUI
import CoreData
import HackerNewsKit
import StoreKit
import Logging

struct Home: View {
    @Environment(Authentication.self) var auth
    @Environment(\.requestReview) private var requestReview
    private var storyVM: StoryViewModel = .shared
    @Bindable private var router: Router = .shared
    private var offlineRepository: OfflineRepository = .shared
    
    @State private var isEulaDialogPresented: Bool = .init()
    @State private var isLoginDialogPresented: Bool = .init()
    @State private var isAboutSheetPresented: Bool = .init()
    @State private var isUrlSheetPresented: Bool = .init()
    @State private var isAbortDownloadAlertPresented: Bool = .init()
    
    @State private var username: String = .init()
    @State private var password: String = .init()
    
    @State private var actionPerformed: Action = .none
    @State private var columnVisibility: NavigationSplitViewVisibility = .doubleColumn
    @State private var showSlideOutMenu: Bool = false
    @State private var dragOffset: Double = 0
    @State private var selectedMenuItem: MenuItem = .home
    private let settings: SettingsViewModel = .shared
    private let appStoreReviewReuqestTrigger = 10
    private let menuWidth: CGFloat = 300
    private static var handledUrl: URL? = nil
    
    var sideMenuScale: CGFloat {
        let baseScaleFactor = 0.95
        let maxScaleFactor = 1.0
        if dragOffset == 0 {
            return showSlideOutMenu ? maxScaleFactor : baseScaleFactor
        }
        let scaleFactor = baseScaleFactor + (0.1 * progress)
        return scaleFactor.clamped(to: baseScaleFactor...maxScaleFactor)
    }
    
    var progress: Double {
        if dragOffset == 0 {
            return showSlideOutMenu ? 1 : 0
        } else if dragOffset > 0 {
            return abs(dragOffset) / menuWidth
        } else {
            return (menuWidth + dragOffset) / menuWidth
        }
    }
    
    var mainContentDimOpacity: CGFloat {
        let maxOpacity = 0.1
        if dragOffset == 0 {
            return showSlideOutMenu ? maxOpacity : 0
        }
        let opacity = maxOpacity * progress
        return opacity
    }
    
    var mainContentDimOverlay: some View {
        Color.black.opacity(mainContentDimOpacity)
            .ignoresSafeArea()
            .clipShape(RoundedRectangle(cornerRadius: 47, style: .continuous))
            .onTapGesture {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                withAnimation(.bouncy.speed(300)) {
                    showSlideOutMenu = false
                }
            }
            .allowsHitTesting(showSlideOutMenu)
    }
    
    var sideMenuDimOpacity: CGFloat {
        let maxOpacity = 0.3
        if dragOffset == 0 {
            return showSlideOutMenu ? 0 : maxOpacity
        }
        let opacity = maxOpacity * (1.0 - progress)
        return opacity
    }
    
    var sideMenuDimOverlay: some View {
        Color.black.opacity(sideMenuDimOpacity)
            .ignoresSafeArea()
            .allowsHitTesting(!showSlideOutMenu)
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Side Menu
            ZStack {
                SideMenu(menuWidth: menuWidth, onDismiss: { selectedItem in
                    withAnimation(.bouncy.speed(300))  {
                        showSlideOutMenu = false
                    }
                    
                    if let selectedItem {
                        withAnimation(.snappy.speed(200)) {
                            selectedMenuItem = selectedItem
                        }
                    }
                })
                .scaleEffect(sideMenuScale, anchor: .center)
                .overlay {
                    sideMenuDimOverlay
                }
            }
            .frame(width: menuWidth + 60, alignment: .leading)
            .background(Color(.secondarySystemBackground))
            .edgesIgnoringSafeArea(.vertical)
            
            ZStack(alignment: .leading) {
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
                        ToolbarItem(placement: .topBarLeading) {
                            Button {
                                withAnimation(.bouncy.speed(300)) {
                                    showSlideOutMenu = !showSlideOutMenu
                                }
                            } label: {
                                Label("Side menu", systemImage: "book.pages")
                                    .labelStyle(.iconOnly)
                                    .foregroundStyle(.foreground)
                                    .glassEffect()
                            }
                            .sensoryFeedback(.impact(flexibility: .soft), trigger: showSlideOutMenu)
                        }
                        if selectedMenuItem == .home {
                            if offlineRepository.isDownloading {
                                ToolbarItem(placement: .topBarTrailing) {
                                    Text("\(offlineRepository.completionCount)")
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
                    .sheet(isPresented: $isAboutSheetPresented, content: {
                        SafariView(url: Constants.githubUrl)
                    })
                    .sheet(isPresented: $isUrlSheetPresented, content: {
                        SafariView(url: Self.handledUrl!)
                    })
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
                                    Self.handledUrl = url
                                    isUrlSheetPresented = true
                                    return
                                }
                                
                                router.to(item)
                            }
                            return .handled
                        } else {
                            Self.handledUrl = url
                            isUrlSheetPresented = true
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
                .clipShape(RoundedRectangle(cornerRadius: 47, style: .continuous))
                .overlay {
                    mainContentDimOverlay
                }
            }
            .id("mainView")
            .offset(x: dragOffset == 0 ? (showSlideOutMenu ? menuWidth : 0) : (dragOffset > 0 ? dragOffset : menuWidth + dragOffset))
            .shadow(radius: 5)
        }
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    let translation = value.translation.width
                    let vector = CGVector(dx: value.location.x - value.startLocation.x, dy: value.location.y - value.startLocation.y)
                    let radians = atan2(vector.dy, vector.dx)
                    let angle = radians * 180 / .pi
                    guard -20...20 ~= angle || 160...180 ~= angle else { return }
                    
                    // If menu is closed, only allow dragging from the left edge (positive)
                    // If menu is open, only allow dragging to the left (negative)
                    if !showSlideOutMenu && translation > 0 {
                        dragOffset = translation
                    } else if showSlideOutMenu && translation < 0 {
                        dragOffset = translation
                    }
                }
                .onEnded { value in
                    let vector = CGVector(dx: value.location.x - value.startLocation.x, dy: value.location.y - value.startLocation.y)
                    let radians = atan2(vector.dy, vector.dx)
                    let angle = radians * 180 / .pi
                    guard -20...20 ~= angle || 160...180 ~= angle else {
                        withAnimation {
                            dragOffset = 0
                        }
                        return
                    }
                    
                    withAnimation(.bouncy.speed(300)) {
                        // Threshold: if dragged more than 1/4 of the width, toggle state
                        if abs(value.translation.width) > menuWidth / 4 {
                            showSlideOutMenu = value.translation.width > 0
                        }
                        dragOffset = 0 // Always reset temporary offset
                    }
                },
            including: .gesture
        )
        .sensoryFeedback(.impact(flexibility: .rigid), trigger: showSlideOutMenu)
        .task(priority: .background) {
            try? await Task.sleep(until: .now + .seconds(2))
            let appOpenCounter = settings.appOpenCounter
            logger.info("Requesting review counter: \(appOpenCounter)")
            if appOpenCounter == appStoreReviewReuqestTrigger {
                requestReview()
                settings.appOpenCounter = appStoreReviewReuqestTrigger + 1
            } else if appOpenCounter < appStoreReviewReuqestTrigger {
                settings.appOpenCounter = appOpenCounter + 1
            }
        }
    }
}
