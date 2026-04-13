import SwiftUI
import AlertToast

struct ToastContainer<Content: View>: View {
    @State private var isToastPresented: Bool = .init()
    @Binding private var actionPerformed: Action

    let content: Content
    let withImage: Bool
    
    init(actionPerformed: Binding<Action>, withImage: Bool = true, @ViewBuilder _ contentBuilder: () -> Content) {
        self.content = contentBuilder()
        self.withImage = withImage
        self._actionPerformed = actionPerformed
    }
    
    var body: some View {
        content
            .toast(isPresenting: $isToastPresented) {
                AlertToast(
                    type: withImage ? .systemImage(actionPerformed.completionIcon, .gray) : .regular,
                    title: actionPerformed.completionLabel
                )
            }
            .onChange(of: actionPerformed) { _, newValue in
                if newValue != .none {
                    isToastPresented = true
                    HapticFeedbackService.shared.trigger(newValue.feedback)
                }
            }
            .onChange(of: isToastPresented) { _, newValue in
                // Reset action after displaying the toast.
                if !newValue {
                    actionPerformed = .none
                }
            }
    }
}
