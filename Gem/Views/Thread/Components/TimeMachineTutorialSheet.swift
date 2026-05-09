import AVKit
import SwiftUI

extension Thread {
    struct TimeMachineTutorialSheet: View {
        let player: AVQueuePlayer
        let looper: AVPlayerLooper
        
        init() {
            let queuePlayer = AVQueuePlayer()
            if let path = Bundle.main.path(forResource: "time_machine", ofType: "m4v") {
                let item = AVPlayerItem(url: URL(fileURLWithPath: path))
                looper = AVPlayerLooper(player: queuePlayer, templateItem: item)
            } else {
                looper = AVPlayerLooper(player: queuePlayer, templateItem: AVPlayerItem(url: URL(fileURLWithPath: "")))
            }
            player = queuePlayer
        }
        
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
        let player: AVQueuePlayer
        
        func makeUIView(context: Context) -> PlayerUIView {
            PlayerUIView(player: player)
        }
        
        func updateUIView(_ uiView: PlayerUIView, context: Context) {}
    }
    
    private class PlayerUIView: UIView {
        private let playerLayer = AVPlayerLayer()
        
        init(player: AVQueuePlayer) {
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
