import Foundation
import SwiftUI

fileprivate struct BorderedFootnote: ViewModifier {
    let backgroundColor: Color
    
    func body(content: Content) -> some View {
        content
            .font(.footnote)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(backgroundColor)
            .cornerRadius(4)
    }
}

extension View {
    func borderedFootnote(backgroundColor: Color = .accent.opacity(0.5)) -> some View {
        modifier(BorderedFootnote(backgroundColor: backgroundColor))
    }
}
