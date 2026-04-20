import SwiftUI
import HackerNewsKit

struct Settings: View {
    @Bindable var store = SettingsStore.shared
    @State var url: IdentifiableURL?
    
    private let githubRepoUrl = URL(string: "https://github.com/Livinglist/Gem")!
    private let githubIssuesUrl = URL(string: "https://github.com/Livinglist/Gem/issues")!
    
    var versionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        List {
            Section {
                Picker("Default Story Type", selection: $store.defaultStoryType) {
                    ForEach(StoryType.allCases, id: \.self) { value in
                        Text(value.label.capitalized)
                            .tag(value)
                    }
                }
            } footer: {
                Text("The type of story to be shown on the launch.")
            }
            
            Section {
                Picker("Default Fetch Mode", selection: $store.defaultFetchMode) {
                    ForEach(FetchMode.allCases, id: \.self) { value in
                        Text(value.label)
                            .tag(value)
                    }
                }
            } footer: {
                Text("Offline mode currently only supports lazy fetching.")
            }
            
            Section {
                Toggle(isOn: $store.isAutomaticDownloadEnabled) {
                    Text("Automatic Download")
                }
                .tint(.accent)
                Toggle(isOn: $store.useCellularData) {
                    Text("Use Cellular Data")
                }
                .tint(.accent)
                .disabled(!store.isAutomaticDownloadEnabled)
                
                Picker("Download Frequency", selection: $store.downloadFrequency) {
                    ForEach(DownloadFrequency.allCases, id: \.self) { value in
                        Text(value.label)
                            .tag(value)
                    }
                }
                .disabled(!store.isAutomaticDownloadEnabled)
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
