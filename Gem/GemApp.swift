import BackgroundTasks
import Foundation
import SwiftUI
import SwiftData
import HackerNewsKit
import UserNotifications

@main
struct GemApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var phase
    var offlineRepository: OfflineRepository = .shared
    
    let auth: Authentication = .shared
    let notification: RepliesViewModel = .shared
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Color(.secondarySystemBackground)
                    .ignoresSafeArea()
                Home()
                    .ignoresSafeArea()
                if offlineRepository.isOfflineReading {
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(.accent.gradient.opacity(0.4))
                            .frame(height: 40)
                            .overlay {
                                Text("Offline Mode")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.foreground.opacity(0.7))
                                    .padding(.bottom, 6)
                            }
                    }
                    .ignoresSafeArea()
                }
            }
            .preferredColorScheme(.dark)
            .onAppear {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
            }
        }
        .environment(auth)
        .onChange(of: phase) { _, newPhase in
            switch newPhase {
            case .background: notification.scheduleFetching()
            default: break
            }
        }
        .backgroundTask(.appRefresh(Constants.AppNotification.backgroundTaskId)) {
            await notification.fetchAllReplies()
        }
    }
}
