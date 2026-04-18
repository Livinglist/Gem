import SwiftUI

struct DownloadMenu: View {
    @ObservedObject var storyStore: StoryStore
    @ObservedObject var offlineRepository: OfflineRepository
    @Binding var isAbortDownloadAlertPresented: Bool
    
    var body: some View {
        Menu {
            if offlineRepository.isDownloading {
                Button {
                    isAbortDownloadAlertPresented = true
                } label: {
                    Label("Abort", systemImage: "stop.circle")
                }
            } else if offlineRepository.isOfflineReading {
                Button {
                    offlineRepository.isOfflineReading = false
                } label: {
                    Label("Exit Offline Mode", systemImage: "airplane.arrival")
                }
            } else {
                Button {
                    offlineRepository.isOfflineReading = true
                } label: {
                    Label("Enter Offline Mode", systemImage: "airplane.departure")
                }
            }
            Divider()
            Button {
                Task {
                    HapticFeedbackService.shared.light()
                    await offlineRepository.downloadAllStories(isTriggerdByUser: true)
                }
            } label: {
                if offlineRepository.isDownloading {
                    Label("Download in progress", systemImage: "hourglass")
                    Text("\(offlineRepository.completionCount) completed")
                } else {
                    Label("Download all stories", systemImage: "square.and.arrow.down")
                    if offlineRepository.lastFetchedAt.isNotEmpty {
                        Text("last downloaded at \(offlineRepository.lastFetchedAt)")
                    }
                }
            }
            .disabled(offlineRepository.isDownloading || !storyStore.isConnectedToNetwork)
        } label: {
            Image(systemName: "square.and.arrow.down.on.square")
                .glassEffect()
                .symbolEffect(.bounce, isActive: offlineRepository.isDownloading)
        }
    }
}
