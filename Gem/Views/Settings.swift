import SwiftUI
import HackerNewsKit

struct Settings: View {
    @Environment(\.openURL) private var openURL
    @Bindable var vm = SettingsViewModel.shared
    @State var url: IdentifiableURL?
    
    private let githubRepoUrl = URL(string: "https://github.com/Livinglist/Gem")!
    private let githubIssuesUrl = URL(string: "https://github.com/Livinglist/Gem/issues")!
    private let appStoreReviewUrl = URL(string: "https://apps.apple.com/us/app/gem/id6762153947?action=write-review")!
    
    var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        List {
            Section {
                Picker("Default Story Type", selection: $vm.defaultStoryType) {
                    ForEach(StoryType.allCases, id: \.self) { value in
                        Text(value.label.capitalized)
                            .tag(value)
                    }
                }
            } footer: {
                Text("The type of story to be shown on the launch.")
            }
            
            Section {
                Picker("Default Fetch Mode", selection: $vm.defaultFetchMode) {
                    ForEach(FetchMode.allCases, id: \.self) { value in
                        Text(value.label)
                            .tag(value)
                    }
                }
            } footer: {
                Text("Offline mode currently only supports lazy fetching.")
            }
            
            Section {
                Toggle(isOn: $vm.isAutoScrollEnabled) {
                    Text("Auto Scroll on Collapse")
                }
                .tint(.accent)
            } header: {
                Text("Thread")
            }
            
            Section {
                Toggle(isOn: $vm.isAutomaticDownloadEnabled) {
                    Text("Automatic Download")
                }
                .tint(.accent)
                Toggle(isOn: $vm.useCellularData) {
                    Text("Use Cellular Data")
                }
                .tint(.accent)
                .disabled(!vm.isAutomaticDownloadEnabled)
                
                Picker("Download Frequency", selection: $vm.downloadFrequency) {
                    ForEach(DownloadFrequency.allCases, id: \.self) { value in
                        Text(value.label)
                            .tag(value)
                    }
                }
                .disabled(!vm.isAutomaticDownloadEnabled)
            } header: {
                Text("Offline Mode")
            } footer: {
                Text("The frequency of background task is throttled by the system, therefore download is not guranteed to respect the frequency.")
            }
            
            Section {
                Button {
                    url = IdentifiableURL(url: githubIssuesUrl)
                } label: {
                    Label("Bug Report", systemImage: "doc.text.below.ecg")
                }
                .foregroundStyle(.accent)
                .brightness(0.2)
                Button {
                    url = IdentifiableURL(url: githubIssuesUrl)
                } label: {
                    Label("Feature Request", systemImage: "star.bubble")
                }
                .foregroundStyle(.accent)
                .brightness(0.2)
                Button {
                    openURL(appStoreReviewUrl)
                } label: {
                    Label("Rate Gem :)", systemImage: "pencil.and.outline")
                }
                .foregroundStyle(.accent)
                .brightness(0.2)
                Button {
                    url = IdentifiableURL(url: githubRepoUrl)
                } label: {
                    Label("Source Code", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                .foregroundStyle(.accent)
                .brightness(0.2)
            } footer: {
                Text(versionString)
            }
        }
        .sheet(item: $url) { url in
            SafariView(url: url.url)
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Settings")
    }
}
