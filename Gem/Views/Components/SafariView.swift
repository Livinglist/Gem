import SwiftUI
import SafariServices

struct SafariView: View {
    @State var presentationDetent: PresentationDetent = .large
    
    let url: URL
    let draggable: Bool
    let heights: Set<PresentationDetent> = [
        .height(100),
        .fraction(0.3),
        .fraction(0.4),
        .fraction(0.5),
        .fraction(0.6),
        .fraction(0.7),
        .fraction(0.8),
        .large
    ]
    
    init(url: URL, draggable: Bool = false) {
        self.url = url
        self.draggable = draggable
    }
    
    var body: some View {
        if draggable {
            ZStack(alignment: .top) {
                SafariBaseView(url: url)
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
            SafariBaseView(url: url)
                .ignoresSafeArea(.all)
        }
    }
}

extension SafariView {
    fileprivate struct SafariBaseView: UIViewControllerRepresentable {
        typealias UIViewControllerType = SFSafariViewController
        
        let url: URL
        
        func makeUIViewController(context: UIViewControllerRepresentableContext<SafariBaseView>) -> SFSafariViewController {
            let controller = SFSafariViewController(url: url)
            controller.preferredControlTintColor = .orange
            controller.dismissButtonStyle = .close
            return controller
        }
        
        func updateUIViewController(_ uiViewController: SFSafariViewController, context: UIViewControllerRepresentableContext<SafariBaseView>) {
        }
    }
}
