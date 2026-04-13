import BackgroundTasks
import Foundation
import SwiftUI
import HackerNewsKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Constants.Download.backgroundTaskId,
                                        using: nil) { task in
            task.expirationHandler = {
                task.setTaskCompleted(success: false)
            }
            
            Task {
                await OfflineRepository.shared.downloadAllStories(isTriggerdByUser: false)
                
                task.setTaskCompleted(success: true)
            }
            
            OfflineRepository.shared.scheduleBackgroundDownload()
        }
    }
    
    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Register SceneDelegate.
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
    
    private func configureUserNotifications() {
        UNUserNotificationCenter.current().delegate = self
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    func sceneDidEnterBackground(_ scene: UIScene) {
        OfflineRepository.shared.scheduleBackgroundDownload()
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        Task {
            let content = response.notification.request.content
            if let id = Int(content.targetContentIdentifier ?? ""),
               id != 0,
               let item = await StoryRepository.shared.fetchComment(id) {
                Router.shared.to(item)
            }
        }
    }
}
