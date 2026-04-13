import Foundation
import SwiftUI

extension View {
    func showShareSheet(url: String) {
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        // Get a scene that's showing (iPad can have many instances of the same app, some in the background)
        let activeScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
                
        let rootViewController = (activeScene?.windows ?? []).first(where: { $0.isKeyWindow })?.rootViewController
                
        // iPad stuff (fine to leave this in for all iOS devices, it will be effectively ignored when not needed)
        activityVC.popoverPresentationController?.sourceView = rootViewController?.view
        activityVC.popoverPresentationController?.sourceRect = .zero
        
        UIApplication.shared.keyWindow?.rootViewController?.present(activityVC, animated: true, completion: nil)
    }
}
