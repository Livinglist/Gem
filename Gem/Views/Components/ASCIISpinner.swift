import SwiftUI
import Combine

struct ASCIISpinner: View {
    let frames = ["|", "/", "-", "\\"]
    @State private var frameIndex = 0
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    let size: CGFloat
    
    init(size: CGFloat = 48.0) {
        self.size = size
    }

    var body: some View {
        Text(frames[frameIndex])
            .font(.system(size: size, design: .monospaced))
            .foregroundStyle(.accent)
            .onReceive(timer) { _ in
                frameIndex = (frameIndex + 1) % frames.count
            }
    }
}
