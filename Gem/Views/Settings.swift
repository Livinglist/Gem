import SwiftUI
import HackerNewsKit

struct Settings: View {
    @ObservedObject var store = SettingsStore.shared

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
                Toggle(isOn: $store.useCellularData) {
                    Text("Use Cellular Data")
                }
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
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle("Settings")
    }
}
