import LinkPresentation
import SwiftUI
import UniformTypeIdentifiers
import HackerNewsKit
import Translation

struct ItemRow: View {
    let item: any Item
    let url: URL?
    let isPinnedStory: Bool
    let isNew: Bool
    let addToRecents: Bool
    
    @Environment(AuthenticationManager.self) var auth
    
    @State private var activeURL: IdentifiableURL?
    @State private var isReplySheetPresented: Bool = .init()
    @State private var isFlagDialogPresented: Bool = .init()
    @State private var isTranslationPresented: Bool = .init()
    @GestureState private var isDetectingPress: Bool = .init()
    @Binding private var actionPerformed: Action
    
    init(item: any Item,
         isPinnedStory: Bool = false,
         isNew: Bool = false,
         addToRecents: Bool = false,
         actionPerformed: Binding<Action>) {
        self.item = item
        self.url = URL(string: item.url ?? "https://news.ycombinator.com/item?id=\(item.id)")
        self.isPinnedStory = isPinnedStory
        self.isNew = isNew
        self.addToRecents = addToRecents
        self._actionPerformed = actionPerformed
    }
    
    var body: some View {
        ZStack {
            Button(
                action: {
                    if item.isJobWithUrl, let urlStr = item.url, let url = URL(string: urlStr) {
                        activeURL = IdentifiableURL(url: url)
                    } else {
                        if addToRecents, let story = item as? Story {
                            RecentsViewModel.shared.insert(story: story)
                        }
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
                                        .foregroundColor(.accent)
                                } else if let text = item.text {
                                    Text(text.replacingOccurrences(of: "\n", with: " "))
                                        .lineLimit(item is Story ? 2 : 4)
                                        .foregroundColor(isNew ? nil : .gray)
                                }
                                Spacer()
                            }.padding(item is Comment ? [.horizontal, .top] : [.horizontal])
                            HStack(alignment: .center) {
                                Text(item.metadata)
                                    .font(.caption)
                                    .padding(.top, 6)
                                    .padding(.leading)
                                    .padding(.bottom, 12)
                                Spacer()
                                if isPinnedStory {
                                    Button {
                                        removePin()
                                    } label: {
                                        Label(String(), systemImage: "pin.fill")
                                            .foregroundStyle(.accent)
                                            .rotationEffect(Angle(degrees: 45))
                                            .transformEffect(.init(translationX: 0, y: 5))
                                    }
                                    
                                } else {
                                    Menu {
                                        ItemMenu(item: item,
                                                 showViewInSeperateThreadOption: false,
                                                 showTranslation: false,
                                                 actionPerformed: $actionPerformed,
                                                 activeURL: $activeURL,
                                                 isFlagDialogPresented: $isFlagDialogPresented,
                                                 isReplySheetPresented: $isReplySheetPresented,
                                                 isTranslationPresented: $isTranslationPresented)
                                    } label: {
                                        Label(String(), systemImage: "ellipsis")
                                            .labelStyle(.iconOnly)
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 12)
                                            .foregroundColor(.accent)
                                            .contentShape(Rectangle())
                                            .glassEffect()
                                            .padding(.trailing, 6)
                                            .padding(.bottom, 6)
                                    }
                                }
                                
                            }
                        }
                    }
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)
                }
            )
            .confirmationDialog("Are you sure?", isPresented: $isFlagDialogPresented) {
                Button("Flag", role: .destructive) {
                    onFlagTap()
                }
            } message: {
                if item is Comment {
                    Text("Flag this comment by \(item.by.orEmpty)?")
                } else {
                    Text("Flag \"\(item.title.orEmpty)\" by \(item.by.orEmpty)?")
                }
            }
            .if(.iOS16 && url != nil) { view in
                view
                    .contextMenu(
                        menuItems: {
                            Button {
                                let urlStr = item.url.ifNullOrEmpty(then: item.itemUrl)
                                let url = URL(string: urlStr)
                                if let url {
                                    activeURL = IdentifiableURL(url: url)
                                }
                            } label: {
                                Label("View in Safari", systemImage: "safari")
                            }
                        },
                        preview: {
                            SafariView(url: url!)
                        })
            }
        }
        .sheet(item: $activeURL) { url in
            SafariView(url: url.url)
        }
        .sheet(isPresented: $isReplySheetPresented) {
            NavigationStack {
                ReplyView(actionPerformed: $actionPerformed,
                          replyingTo: item,
                          draggable: true
                )
            }
        }
    }
    
    private func removePin() {
        PinsViewModel.shared.remove(item)
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
