import LinkPresentation
import SwiftUI
import UniformTypeIdentifiers
import HackerNewsKit

struct ItemRow: View {
    let settings: SettingsStore = .shared
    let item: any Item
    let url: URL?
    let isPinnedStory: Bool

    @EnvironmentObject var auth: Authentication

    @State private var isSafariSheetPresented: Bool = .init()
    @State private var isHNSheetPresented: Bool = .init()
    @State private var isReplySheetPresented: Bool = .init()
    @State private var isFlagDialogPresented: Bool = .init()
    @GestureState private var isDetectingPress: Bool = .init()
    @Binding private var actionPerformed: Action
    
    init(item: any Item,
         isPinnedStory: Bool = false,
         actionPerformed: Binding<Action>) {
        self.item = item
        self.url = URL(string: item.url ?? "https://news.ycombinator.com/item?id=\(item.id)")
        self.isPinnedStory = isPinnedStory
        self._actionPerformed = actionPerformed
    }

    @ViewBuilder
    var menu: some View {
        Menu {
            UpvoteButton(id: item.id, actionPerformed: $actionPerformed)
            DownvoteButton(id: item.id, actionPerformed: $actionPerformed)
            FavButton(id: item.id, actionPerformed: $actionPerformed)
            PinButton(id: item.id, actionPerformed: $actionPerformed)
            Divider()
            FlagButton(id: item.id, showFlagDialog: $isFlagDialogPresented)
            Divider()
            ShareMenu(item: item)
            Button {
                isHNSheetPresented = true
            } label: {
                Label("View on Hacker News", systemImage: "safari")
            }
        } label: {
            Label(String(), systemImage: "ellipsis")
                .padding(.leading)
                .padding(.bottom, 12)
                .foregroundColor(.orange)
        }
    }

    var body: some View {
        ZStack {
            Button(
                action: {
                    if item.isJobWithUrl {
                        isSafariSheetPresented = true
                    } else {
                        Router.shared.to(item)
                    }
                },
                label: {
                    HStack {
                        VStack {
                            if item is Story {
                                Text(item.title.orEmpty)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .multilineTextAlignment(.leading)
                                    .padding([.horizontal, .top])
                                Spacer()
                            }
                            HStack {
                                if let url = item.readableUrl {
                                    Text(url)
                                        .font(.footnote)
                                        .foregroundColor(.orange)
                                } else if let text = item.text {
                                    Text(text.replacingOccurrences(of: "\n", with: " "))
                                        .font(.footnote)
                                        .lineLimit(2)
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }.padding(item is Comment ? [.horizontal, .top] : [.horizontal])
                            Divider().frame(maxWidth: .infinity)
                            HStack(alignment: .center) {
                                Text(item.metadata)
                                    .font(.caption)
                                    .padding(.top, 6)
                                    .padding(.leading)
                                    .padding(.bottom, 12)
                                Spacer()
                                if isPinnedStory {
                                    Button {
                                        onPin()
                                    } label: {
                                        Label(String(), systemImage: "pin.fill")
                                            .rotationEffect(Angle(degrees: 45))
                                            .transformEffect(.init(translationX: 0, y: 5))
                                    }

                                } else {
                                    menu
                                }

                            }
                        }
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)
                }
            )
            .if(.iOS16 && url != nil) { view in
                view
                    .contextMenu(
                    menuItems: {
                        Button {
                            isSafariSheetPresented = true
                        } label: {
                            Label("View in browser", systemImage: "safari")
                        }
                    },
                    preview: {
                        SafariView(url: url!)
                    })
            }
        }
        .confirmationDialog("Are you sure?", isPresented: $isFlagDialogPresented) {
            Button("Flag", role: .destructive) {
                onFlagTap()
            }
        } message: {
            Text("Flag \"\(item.title.orEmpty)\" by \(item.by.orEmpty)?")
        }
        .sheet(isPresented: $isHNSheetPresented) {
            if let url = URL(string: item.itemUrl) {
                SafariView(url: url)
            }
        }
        .sheet(isPresented: $isSafariSheetPresented) {
            let urlStr = item.url.ifNullOrEmpty(then: item.itemUrl)
            if let url = URL(string: urlStr) {
                SafariView(url: url)
            }
        }
    }
    
    private func onPin() {
        settings.onPinToggle(item.id)
        HapticFeedbackService.shared.light()
    }

    private func onFlagTap() {
        Task {
            let res = await auth.flag(item.id)

            if res {
                actionPerformed = .flag
            } else {
                actionPerformed = .failure
            }
        }
    }
}
