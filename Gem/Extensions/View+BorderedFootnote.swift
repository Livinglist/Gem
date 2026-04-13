import Foundation
import SwiftUI

fileprivate struct BorderedFootnote: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.footnote)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(4)
    }
}

extension View {
    func borderedFootnote() -> some View {
        modifier(BorderedFootnote())
    }
}
