import SwiftUI
import HackerNewsKit

struct ReplyView: View {
    @EnvironmentObject private var auth: Authentication
    @Environment(\.presentationMode) private var presentationMode
    @FocusState private var focusState: FocusField?
    @State private var presentationDetent: PresentationDetent = .large
    @State private var text: String = .init()
    
    enum FocusField: Hashable {
      case field
    }
    
    var actionPerformed: Binding<Action>?
    let replyingTo: any Item
    let draggable: Bool
    let heights: Set<PresentationDetent> = [
        .height(320),
        .large
    ]
    
    init(actionPerformed: Binding<Action>? = nil, replyingTo: any Item, draggable: Bool = false) {
        self.actionPerformed = actionPerformed
        self.replyingTo = replyingTo
        self.draggable = draggable
    }
    
    @ViewBuilder
    var mainView: some View {
        VStack(spacing: 0) {
            TextField("", text: $text,  axis: .vertical)
                .lineLimit(10...100)
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 12)
                        .glassEffect(.clear, in: .rect(cornerRadius: 12)) // New in iOS 26
                }
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .focused($focusState, equals: .field)
                .task {
                    focusState = .field
                }
                .padding(.top, 80)
            Spacer()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Cancel", role: .cancel) {
                    self.presentationMode.wrappedValue.dismiss()
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    guard text.trimmingCharacters(in: .whitespaces).isNotEmpty else { return }
                    Task {
                        let res = await auth.reply(to: replyingTo.id, with: text)
                        
                        if res {
                            actionPerformed?.wrappedValue = .reply
                        } else {
                            actionPerformed?.wrappedValue = .failure
                        }
                    }
                    self.presentationMode.wrappedValue.dismiss()
                } label: {
                    Label("Submit", systemImage: "")
                        .labelStyle(.titleOnly)
                        .foregroundStyle(.foreground.opacity(0.7))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 6)
                        .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .tint(.accent.opacity(0.6))
                .buttonStyle(.glassProminent)
            }
        }
        .containerBackground(.clear, for: .navigation)
    }
    
    var body: some View {
        if draggable {
            ZStack(alignment: .top) {
                mainView
                // Workaround for increasing the size of draggable area.
                Color
                    .white.opacity(0.001)
                    .frame(width: 150, height: 50)
            }
            .ignoresSafeArea(.all)
            .presentationDetents(heights, selection: $presentationDetent)
            .presentationBackgroundInteraction(.enabled)
            .interactiveDismissDisabled()
            .navigationTitle("Replying to \(replyingTo.by ?? "")")
            .navigationBarTitleDisplayMode(.inline)
        } else {
            mainView
                .navigationTitle("Replying to \(replyingTo.by ?? "")")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
