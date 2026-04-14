import SwiftUI
import CoreData
import HackerNewsKit

struct MenuRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.secondary)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
            
            Spacer()
        }
        .contentShape(Rectangle())
    }
}

struct SideMenuView: View {
    let menuWidth: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 1. Header / Logo Area
            Text("Claude")
                .font(.system(size: 24, weight: .semibold, design: .serif))
                .padding(.horizontal)
                .padding(.top, 60)
            
            // 2. Menu Items
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    MenuRow(icon: "bubble.left.and.bubble.right", title: "Chat History")
                    MenuRow(icon: "star", title: "Starred")
                    MenuRow(icon: "plus.circle", title: "New Chat")
                    
                    Divider()
                        .padding(.vertical, 10)
                    
                    MenuRow(icon: "gearshape", title: "Settings")
                    MenuRow(icon: "questionmark.circle", title: "Help & Support")
                }
                .padding()
            }
            
            Spacer()
            
            // 3. User Profile Section (Bottom)
            Divider()
            HStack {
                Circle()
                    .fill(Color.orange.opacity(0.8))
                    .frame(width: 32, height: 32)
                    .overlay(Text("JD").font(.caption).bold().foregroundColor(.white))
                
                Text("John Doe")
                    .font(.body)
                
                Spacer()
                
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
        }
        .frame(width: menuWidth, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .edgesIgnoringSafeArea(.vertical)
    }
}

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
    private let menuWidth: CGFloat = 300
    private static var handledUrl: URL? = nil
    
    var body: some View {
        if UIDevice.current.userInterfaceIdiom == .phone {
            ZStack(alignment: .leading) {
                ZStack(alignment: .leading) {
                    Color(.secondarySystemBackground)
                    mainView
                        .background(
                            RoundedRectangle(cornerRadius: 47, style: .continuous)
                                // Shadow on the right side (x: 5) to simulate depth from the menu
                                .shadow(color: .black.opacity(0.3), radius: 30, x: -12, y: 0)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 47, style: .continuous))
//                    // Ambient shadow
//                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: -1, y: 0)
//                    // Depth shadow
//                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: -10, y: 0)
                    // Dimmed Overlay
//                    if showSlideOutMenu {
//                        Color.black.opacity(0.3)
//                            .ignoresSafeArea()
//                            .clipShape(RoundedRectangle(cornerRadius: 47, style: .continuous))
//                            .onTapGesture { withAnimation { showSlideOutMenu = false } }
//                    }
                }
                .offset(x: dragOffset == 0 ? (showSlideOutMenu ? menuWidth : 0) : (dragOffset > 0 ? dragOffset : menuWidth + dragOffset))

                // Side Menu
                SideMenuView(menuWidth: menuWidth)
                    .offset(x: dragOffset == 0 ? (showSlideOutMenu ? 0 : -menuWidth) : (dragOffset > 0 ? (-menuWidth + dragOffset) : dragOffset))

            }
            .animation(.spring(), value: showSlideOutMenu)
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
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
            //            Button {
            //                Router.shared.to(.pin)
            //            } label: {
            //                Label("Pins", systemImage: "pin")
            //            }
            //            .listRowSeparator(.hidden)
            
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
        storyList
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showSlideOutMenu = !showSlideOutMenu
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    } label: {
                        Image(systemName: "book.pages")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 24)
                    }
                    .glassEffect(.clear, in: Circle())
                }
                ToolbarItem(placement: .principal) {
                    Menu {
                        ForEach(StoryType.allCases, id: \.self) { storyType in
                            Button {
                                storyStore.storyType = storyType
                                
                                Task {
                                    await storyStore.fetchStories()
                                }
                            } label: {
                                Label("\(storyType.label.capitalized)", systemImage: storyType.icon)
                            }
                            .disabled(offlineRepository.isOfflineReading && !storyType.isDownloadable)
                        }
                    } label: {
                        HStack {
                            Text(storyStore.storyType.label.capitalized)
                                .font(.headline)
                                .foregroundStyle(.foreground)
                            Image(systemName: "chevron.down")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 8)
                        }
                    }
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
            .alert("Login", isPresented: $isLoginDialogPresented, actions: {
                TextField("Username", text: $username)
                    .autocorrectionDisabled(true)
                    .textInputAutocapitalization(.never)
                SecureField("Password", text: $password)
                Button(Action.login.label, action: {
                    if username.isNotEmpty && password.isNotEmpty {
                        self.isEulaDialogPresented = true
                    }
                })
                .foregroundStyle(.purple)
                Button("Cancel", role: .cancel, action: {}).foregroundStyle(.purple)
            }, message: {
                Text("Please enter your username and password.")
            })
            .sheet(isPresented: $isEulaDialogPresented) {
                ZStack(alignment: .bottom) {
                    if let url = URL(string: "https://news.ycombinator.com/newsguidelines.html") {
                        WebView(url: url)
                            .ignoresSafeArea()
                    }
                    
                    VStack {
                        Text("By signing in, you are agreeing to the Hacker News Guidelines.")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                            .padding(.top, 12)
                            .font(.callout)
                        HStack {
                            Button {
                                HapticFeedbackService.shared.ultralight()
                                self.isEulaDialogPresented = false
                            } label: {
                                Text("Reject")
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(BorderedButtonStyle())
                            .frame(maxWidth: .infinity)
                            .padding(.bottom)
                            
                            Spacer()
                            
                            Button {
                                HapticFeedbackService.shared.ultralight()
                                self.isEulaDialogPresented = false
                                
                                guard username.isNotEmpty && password.isNotEmpty else {
                                    HapticFeedbackService.shared.error()
                                    return
                                }
                                
                                Task {
                                    let res = await auth.logIn(username: username, password: password, shouldRememberMe: true)
                                    
                                    if res {
                                        actionPerformed = .login
                                    } else {
                                        actionPerformed = .failure
                                    }
                                }
                            } label: {
                                Text("Accept")
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 12)
                                    .foregroundStyle(.purple)
                                    .fontWeight(.bold)
                            }
                            .buttonStyle(BorderedButtonStyle())
                            .frame(maxWidth: .infinity)
                            .padding(.bottom)
                        }
                    }
                    .padding()
                    .background {
                        Rectangle()
                            .fill(.background)
                            .cornerRadius(16)
                            .padding()
                            .shadow(radius: 4.0)
                    }
                }
                .presentationDetents([.large])
            }
            .task {
                await storyStore.fetchStories()
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
