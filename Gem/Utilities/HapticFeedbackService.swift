import Foundation
import UIKit

class HapticFeedbackService {
    static let shared: HapticFeedbackService = HapticFeedbackService()
    
    private let generator = UINotificationFeedbackGenerator()
    private let impactGenerator = UIImpactFeedbackGenerator()
    
    private init() {}
    
    func success() -> Void {
        generator.notificationOccurred(.success)
    }
    
    func error() -> Void {
        generator.notificationOccurred(.error)
    }
    
    func warning() -> Void {
        generator.notificationOccurred(.warning)
    }
    
    func light() -> Void {
        impactGenerator.impactOccurred(intensity: 0.6)
    }
    
    func ultralight() -> Void {
        impactGenerator.impactOccurred(intensity: 0.3)
    }

    func trigger(_ feedback: UINotificationFeedbackGenerator.FeedbackType) -> Void {
        generator.notificationOccurred(feedback)
    }
}
