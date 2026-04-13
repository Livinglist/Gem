import SwiftUI

// MARK: - Custom Menu Context Implementation
struct PreviewContextMenu<Content: View> {
    let destination: Content
    let actionProvider: UIContextMenuActionProvider?
    
    init(destination: Content, actionProvider: UIContextMenuActionProvider? = nil) {
        self.destination = destination
        self.actionProvider = actionProvider
    }
}

// UIView wrapper with UIContextMenuInteraction
struct PreviewContextView<Content: View>: UIViewRepresentable {
    
    let menu: PreviewContextMenu<Content>
    let didCommitView: () -> Void
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let menuInteraction = UIContextMenuInteraction(delegate: context.coordinator)
        view.addInteraction(menuInteraction)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(menu: self.menu, didCommitView: self.didCommitView)
    }
    
    class Coordinator: NSObject, UIContextMenuInteractionDelegate {
        
        let menu: PreviewContextMenu<Content>
        let didCommitView: () -> Void
        
        init(menu: PreviewContextMenu<Content>, didCommitView: @escaping () -> Void) {
            self.menu = menu
            self.didCommitView = didCommitView
        }
        
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
            return UIContextMenuConfiguration(identifier: nil, previewProvider: { () -> UIViewController? in
                UIHostingController(rootView: self.menu.destination)
            }, actionProvider: self.menu.actionProvider)
        }
        
        func contextMenuInteraction(_ interaction: UIContextMenuInteraction, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
            animator.addCompletion(self.didCommitView)
        }
        
    }
}

struct PreviewContextViewModifier<V: View>: ViewModifier {
    let menu: PreviewContextMenu<V>
    @Environment(\.presentationMode) var mode
    
    @State var isActive: Bool = .init()
    
    func body(content: Content) -> some View {
        content.overlay(PreviewContextView(menu: menu, didCommitView: { self.isActive = true }))
    }
}
