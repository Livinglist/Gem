import Foundation
import SwiftUI

extension View {
    func contextMenu<Content: View>(_ menu: PreviewContextMenu<Content>) -> some View {
        self.modifier(PreviewContextViewModifier(menu: menu))
    }
}
