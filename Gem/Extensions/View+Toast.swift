import SwiftUI

extension View {
    func withToast(actionPerformed: Binding<Action>) -> some View {
        ToastContainer(actionPerformed: actionPerformed) {
            self
        }
    }
    
    /// Display toast without image.
    func withPlainToast(actionPerformed: Binding<Action>) -> some View {
        ToastContainer(actionPerformed: actionPerformed, withImage: false) {
            self
        }
    }
}

