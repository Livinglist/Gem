import SwiftUI

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

enum MenuItem: String, Hashable, Sendable, CaseIterable {
    case home = "house", pinned = "pin", favorites = "heart.rectangle", replies = "bell.badge", search = "magnifyingglass"
    
    var label: String {
        switch self {
        case .home: "Home"
        case .pinned: "Pins"
        case .favorites: "Favorites"
        case .replies: "Replies"
        case .search: "Search"
        }
    }
}

struct SideMenu: View {
    let menuWidth: CGFloat
    let onDismiss: (MenuItem?) -> Void
    
    @EnvironmentObject private var auth: Authentication
    @State private var selectedMenuItem: MenuItem = .home
    @State private var username: String = .init()
    @State private var password: String = .init()
    @State private var isEulaDialogPresented: Bool = .init()
    @State private var isLoginDialogPresented: Bool = .init()
    @State private var isSettingsPresented: Bool = .init()
    @State private var actionPerformed: Action = .none
    
    @Namespace private var namespace
    
    struct MenuButton: View {
        @Binding var selectedMenuItem: MenuItem
        let menuItem: MenuItem
        let namespace: Namespace.ID
        let onTap: () -> Void
        
        var body: some View {
            Button {
                withAnimation {
                    selectedMenuItem = menuItem
                }
                onTap()
            } label: {
                MenuRow(icon: menuItem.rawValue, title: menuItem.label)
                    .padding()
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.impact(flexibility: .soft), trigger: selectedMenuItem)
            .if(selectedMenuItem == menuItem) { view in
                view
                    .glassEffect()
                    .glassEffectUnion(id: menuItem, namespace: namespace)
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 0) {
                ScrollView {
                    GlassEffectContainer {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(MenuItem.allCases, id: \.self) { menuItem in
                                MenuButton(selectedMenuItem: $selectedMenuItem, menuItem: menuItem, namespace: namespace) {
                                    onDismiss(menuItem)
                                }
                            }
                        }
                        .padding()
                        .padding(.top, 80)
                    }
                    
                    RecentsView(onDismiss: onDismiss)
                        .padding()
                        .padding(.bottom, 100)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollIndicators(.hidden)
                
                Spacer()
            }
            
            HStack {
                AuthButton(isLoginDialogPresented: $isLoginDialogPresented)
                    .ignoresSafeArea()
                
                Spacer()
                
                Button {
                    isSettingsPresented = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.foreground)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 6)
                        .frame(width: 48, height: 48)
                }
                .sensoryFeedback(.impact(flexibility: .soft), trigger: isSettingsPresented)
                .tint(.accent.opacity(0.6))
                .buttonBorderShape(.circle)
                .glassEffect(.regular.tint(.accent.opacity(0.4)).interactive())
                .padding(.leading, 12)
            }
            .padding()
            .padding(.bottom, 12)
            
            VStack(alignment: .leading, spacing: 0) {
                Color(.secondarySystemBackground)
                    .opacity(0.9)
                    .frame(width: menuWidth, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .blur(radius: 16)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 0) {
                Text("Gem")
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .padding(.horizontal)
                    .padding(.top, 60)
                    .foregroundStyle(.accent.opacity(0.3))
                Spacer()
            }
            .blur(radius: 2)
            
            VStack(alignment: .leading, spacing: 0) {
                Text("Gem")
                    .font(.system(size: 24, weight: .semibold, design: .serif))
                    .padding(.horizontal)
                    .padding(.top, 60)
                Spacer()
            }
        }
        .frame(width: menuWidth, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .edgesIgnoringSafeArea(.vertical)
        .sheet(isPresented: $isSettingsPresented) {
            Settings()
                .presentationDragIndicator(.visible)
        }
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
            Text("Please enter your Hacker News username and password.")
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
        .withToast(actionPerformed: $actionPerformed)
    }
}
