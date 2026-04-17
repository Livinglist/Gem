import SwiftUI
import CoreData
import HackerNewsKit

struct Home: View {
    @EnvironmentObject private var auth: Authentication
    @StateObject private var storyStore: StoryStore = .init()
    @ObservedObject private var settings: SettingsStore = .shared
    @ObservedObject private var router: Router = .shared
    @ObservedObject private var offlineRepository: OfflineRepository = .shared
    
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
        if UIDevice.current.userInterfaceIdiom == .phone {
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
                    mainView
                        .clipShape(RoundedRectangle(cornerRadius: 47, style: .continuous))
                        .overlay {
                            mainContentDimOverlay
                        }
                }
                .id("mainView")
                .offset(x: dragOffset == 0 ? (showSlideOutMenu ? menuWidth : 0) : (dragOffset > 0 ? dragOffset : menuWidth + dragOffset))
                .shadow(radius: 5)
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let translation = value.translation.width
                        
                        // If menu is closed, only allow dragging from the left edge (positive)
                        // If menu is open, only allow dragging to the left (negative)
                        if !showSlideOutMenu && translation > 0 {
                            dragOffset = translation
                        } else if showSlideOutMenu && translation < 0 {
                            dragOffset = translation
                        }
                    }
                    .onEnded { value in
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            
                            // Threshold: if dragged more than 1/3 of the width, toggle state
                            if abs(value.translation.width) > menuWidth / 3 {
                                showSlideOutMenu = value.translation.width > 0
                                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                            }
                            dragOffset = 0 // Always reset temporary offset
                        }
                    }
            )
        } else {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                mainView
            } detail: {
                NavigationStack(path: $router.path) {
                    Text("Tap on a story to its comments")
                        .navigationDestination(for: Comment.self) { cmt in
                            Thread(item: cmt, level: 0)
                        }
                        .navigationDestination(for: Story.self) { story in
                            Thread(item: story, level: 0)
                        }
                        .navigationDestination(for: Destination.self) { val in
                            val.toView()
                        }
                }
            }
            .navigationSplitViewStyle(.balanced)
            .tint(.purple)
        }
    }
    
    @ViewBuilder
    var storyList: some View {
        List {
            if storyStore.status.isLoading {
                HStack {
                    Spacer()
                    LoadingIndicator().frame(height: 200)
                    Spacer()
                }
                .listRowSeparator(.hidden)
            } else if !storyStore.isConnectedToNetwork && !offlineRepository.isOfflineReading && storyStore.stories.isEmpty {
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        Image(systemName: "exclamationmark.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundStyle(.purple)
                            .padding(.bottom, 24)
                        Text("Not connected to network, you can try entering offline mode from the top right menu.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 48)
                    }
                    Spacer()
                }
                .frame(height: 240)
                .listRowSeparator(.hidden)
            } else {
                ForEach(storyStore.stories) { story in
                    ItemRow(item: story,
                            actionPerformed: $actionPerformed)
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .listRowSeparator(.hidden)
                    .onAppear {
                        storyStore.onStoryRowAppear(story)
                    }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await storyStore.refresh()
        }
        //        .toolbar {
        //            ToolbarItem {
        //                Button {
        //                    router.to(Destination.search)
        //                } label: {
        //                    Image(systemName: "magnifyingglass")
        //                }
        //            }
        //            ToolbarItem {
        //                Button {
        //                    router.to(Destination.fav)
        //                } label: {
        //                    Image(systemName: "heart")
        //                }
        //            }
        //            ToolbarItem {
        //                Menu {
        //                    ForEach(StoryType.allCases, id: \.self) { storyType in
        //                        Button {
        //                            storyStore.storyType = storyType
        //
        //                            Task {
        //                                await storyStore.fetchStories()
        //                            }
        //                        } label: {
        //                            Label("\(storyType.label.capitalized)", systemImage: storyType.icon)
        //                        }
        //                        .disabled(offlineRepository.isOfflineReading && !storyType.isDownloadable)
        //                    }
        //                    Divider()
        //                    Button {
        //                        Task {
        //                            HapticFeedbackService.shared.light()
        //                            await offlineRepository.downloadAllStories(isTriggerdByUser: true)
        //                        }
        //                    } label: {
        //                        if offlineRepository.isDownloading {
        //                            Text("Download in progress")
        //                            Text("\(offlineRepository.completionCount) completed")
        //                        } else {
        //                            Label("Download all stories", systemImage: "square.and.arrow.down")
        //                            if offlineRepository.lastFetchedAt.isNotEmpty {
        //                                Text("last downloaded at \(offlineRepository.lastFetchedAt)")
        //                            }
        //                        }
        //                    }
        //                    .disabled(offlineRepository.isDownloading || !storyStore.isConnectedToNetwork)
        //                    if offlineRepository.isDownloading {
        //                        Button {
        //                            isAbortDownloadAlertPresented = true
        //                        } label: {
        //                            Text("Abort")
        //                        }
        //                    } else if offlineRepository.isOfflineReading {
        //                        Button {
        //                            offlineRepository.isOfflineReading = false
        //                        } label: {
        //                            Text("Exit Offline Mode")
        //                        }
        //                    } else {
        //                        Button {
        //                            offlineRepository.isOfflineReading = true
        //                        } label: {
        //                            Text("Enter Offline Mode")
        //                        }
        //                    }
        //                    Divider()
        //                    AuthButton(isLoginDialogPresented: $isLoginDialogPresented)
        //                    NavigationLink {
        //                        Settings()
        //                    } label: {
        //                        Text("Settings")
        //                    }
        //                    Button {
        //                        isAboutSheetPresented = true
        //                    } label: {
        //                        Text("About")
        //                    }
        //                } label: {
        //                    if offlineRepository.isDownloading {
        //                        ProgressView()
        //                            .progressViewStyle(.circular)
        //                    } else {
        //                        Image(systemName: "list.bullet")
        //                    }
        //                }
        //            }
        //        }
        //        .toolbar {
        //            ToolbarItem(placement: .principal) {
        //                Menu {
        //                    Button("Settings") { /* action */ }
        //                    Button("Profile") { /* action */ }
        //                } label: {
        //                    Text(storyStore.storyType.label.capitalized)
        //                        .font(.headline)
        //                }
        //            }
        //        }
        //.navigationTitle(storyStore.storyType.label.uppercased())
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
    }
    
    @ViewBuilder
    var mainView: some View {
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
        }
        .toolbarTitleDisplayMode(.inline)
        .if(UIDevice.current.userInterfaceIdiom == .phone) { view in
            view
                .navigationDestination(for: Comment.self) { cmt in
                    Thread(item: cmt, level: 0)
                }
                .navigationDestination(for: Story.self) { story in
                    Thread(item: story, level: 0)
                }
                .navigationDestination(for: Destination.self) { val in val.toView() }
        }
        .if(UIDevice.current.userInterfaceIdiom == .phone) { view in
            NavigationStack(path: $router.path) {
                view
            }
        }
        .withToast(actionPerformed: $actionPerformed)
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
    }
}
