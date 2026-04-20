import SwiftUI
import HackerNewsKit

struct Stories: View {
    private var vm: StoryViewModel = .shared
    private var offlineRepository: OfflineRepository = .shared
    @State private var actionPerformed: Action = .none
    
    var navigationTitle: String {
        switch vm.storyType {
        case .ask: "Ash HN"
        case .best: "Best stories"
        case .jobs: "YC Jobs"
        case .new: "New stories"
        case .show: "Show HN"
        case .top: "Top stories"
        }
    }
    
    var body: some View {
        List {
            if vm.status.isLoading {
                HStack {
                    Spacer()
                    ASCIISpinner().frame(height: 200)
                    Spacer()
                }
                .listRowSeparator(.hidden)
            } else if !vm.isConnectedToNetwork && !offlineRepository.isOfflineReading && vm.stories.isEmpty {
                HStack {
                    Spacer()
                    VStack {
                        Spacer()
                        Image(systemName: "exclamationmark.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                            .foregroundStyle(.accent)
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
                ForEach(vm.stories) { story in
                    ItemRow(item: story,
                            addToRecents: true,
                            actionPerformed: $actionPerformed)
                    .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                    .listRowSeparator(.hidden)
                    .onAppear {
                        vm.onStoryRowAppear(story)
                    }
                }
            }
        }
        .listStyle(.plain)
        .refreshable {
            await vm.refresh()
        }
        .sensoryFeedback(.success, trigger: vm.status) { $1.isCompleted }
        .sensoryFeedback(.selection, trigger: vm.storyType)
        .withToast(actionPerformed: $actionPerformed)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Menu {
                    ForEach(StoryType.allCases, id: \.self) { storyType in
                        Button {
                            if vm.storyType == storyType { return }
                            withAnimation(.snappy.speed(200)) {
                                vm.storyType = storyType
                            }
                        } label: {
                            Label("\(storyType.label.capitalized)", systemImage: storyType.icon)
                        }
                        .disabled(offlineRepository.isOfflineReading && !storyType.isDownloadable)
                    }
                } label: {
                    HStack {
                        Text(vm.storyType.label.capitalized)
                            .font(.headline)
                            .foregroundStyle(.foreground)
                        Image(systemName: "chevron.down")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 8)
                    }
                    .frame(minWidth: 80, alignment: .center)
                }
            }
        }
        .onChange(of: vm.storyType) {
            Task {
                await vm.fetchStories()
            }
        }
        .navigationTitle(navigationTitle)
    }
}
