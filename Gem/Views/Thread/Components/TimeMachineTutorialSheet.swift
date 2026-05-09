import AVKit
import SwiftUI

extension Thread {
    struct TimeMachineTutorialSheet: View {
        private let player: AVPlayer = {
            guard let path = Bundle.main.path(forResource: "time_machine", ofType: "m4v") else {
                return AVPlayer()
            }
            return AVPlayer(url: URL(fileURLWithPath: path))
        }()
        
        var body: some View {
            ZStack(alignment: .top) {
                AVPlayerView(player: player)
                    .ignoresSafeArea(edges: .bottom)
                    .padding(.top, 48)
                    .onAppear { player.play() }
                    .onDisappear { player.pause() }
                
                VStack(alignment: .center) {
                    Text("Time Machine")
                        .font(.title)
                        .foregroundStyle(.white)
                        .padding(.top, 24)
                    Text("Swipe from right edge to left on a comment to see its ancestors")
                        .font(.body)
                        .foregroundStyle(.white)
                }
            }
        }
    }
    
    private struct AVPlayerView: UIViewRepresentable {
        let player: AVPlayer
        
        func makeUIView(context: Context) -> PlayerUIView {
            PlayerUIView(player: player)
        }
        
        func updateUIView(_ uiView: PlayerUIView, context: Context) {}
    }
    
    private class PlayerUIView: UIView {
        private let playerLayer = AVPlayerLayer()
        
        init(player: AVPlayer) {
            super.init(frame: .zero)
            playerLayer.player = player
            playerLayer.videoGravity = .resizeAspect
            layer.addSublayer(playerLayer)
        }
        
        required init?(coder: NSCoder) { fatalError() }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            playerLayer.frame = bounds
        }
    }
}
