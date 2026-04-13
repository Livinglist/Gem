import SwiftUI

struct LoadingIndicator: View {
    @State private var shouldAnimate: Bool = .init()
    let size: CGFloat = 12
    let color: Color
    
    init(color: Color = .orange) {
        self.color = color
    }
    
    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .scaleEffect(shouldAnimate ? 1.0 : 0.5)
                .animation(.easeInOut(duration: 0.5).repeatForever(), value: shouldAnimate)
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .scaleEffect(shouldAnimate ? 1.0 : 0.5)
                .animation(.easeInOut(duration: 0.5).repeatForever().delay(0.3), value: shouldAnimate)
            Circle()
                .fill(color)
                .frame(width: size, height: size)
                .scaleEffect(shouldAnimate ? 1.0 : 0.5)
                .animation(.easeInOut(duration: 0.5).repeatForever().delay(0.6), value: shouldAnimate)
        }
        .onAppear {
            self.shouldAnimate = true
        }
    }
    
}

struct LoadingIndicator_Previews: PreviewProvider {
    static var previews: some View {
        LoadingIndicator()
    }
}
