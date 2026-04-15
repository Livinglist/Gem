import SwiftUI
import HackerNewsKit

struct Stories: View {
    @ObservedObject private var storyStore: StoryStore = .shared
    @ObservedObject private var offlineRepository: OfflineRepository = .shared
    @State private var actionPerformed: Action = .none
    
    var body: some View {
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
        .withToast(actionPerformed: $actionPerformed)
        .toolbar {
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
    }
}
