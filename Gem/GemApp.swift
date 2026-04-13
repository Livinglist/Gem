import BackgroundTasks
import Foundation
import SwiftUI
import SwiftData
import HackerNewsKit
import UserNotifications

@main
struct ZCombinatorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var phase
    @ObservedObject var offlineRepository: OfflineRepository = .shared

    let auth: Authentication = .shared
    let notification: AppNotification = .shared

    var body: some Scene {
        WindowGroup {
            ZStack {
                Home()
                if offlineRepository.isOfflineReading {
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(.orange.gradient.opacity(0.4))
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
            .environmentObject(auth)
            .onAppear {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
            }
        }
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
