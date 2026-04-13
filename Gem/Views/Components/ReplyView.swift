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
            HStack {
                Button("Cancel", role: .cancel) {
                    self.presentationMode.wrappedValue.dismiss()
                }
                .padding()
                Spacer()
                Button("Submit") {
                    Task {
                        let res = await auth.reply(to: replyingTo.id, with: text)
                        
                        if res {
                            actionPerformed?.wrappedValue = .reply
                        } else {
                            actionPerformed?.wrappedValue = .failure
                        }
                    }
                    self.presentationMode.wrappedValue.dismiss()
                }
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding()
            }
            HStack {
                Text("Replying to \(replyingTo.by.orEmpty)")
                    .font(.footnote)
                    .padding(.leading, 12)
                    .padding(.bottom, 12)
                Spacer()
            }
            TextField("", text: $text,  axis: .vertical)
                .lineLimit(10...100)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal, 12)
                .focused($focusState, equals: .field)
                .task {
                    focusState = .field
                }
            Spacer()
        }
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
        } else {
            mainView
        }
    }
}
