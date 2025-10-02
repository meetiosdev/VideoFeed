import SwiftUI
import AVKit

struct VideoPlayerView: View {
    var player: AVPlayer?
    @Binding var isActive: Bool
    var accessibilityId: Int

    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        if isActive { player.play() }
                        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                            player.seek(to: .zero)
                            player.play()
                        }
                    }
                    .onDisappear {
                        player.pause()
                        player.seek(to: .zero)
                    }
                    .accessibilityLabel("Video Player \(accessibilityId)")
            } else {
                ProgressView()
            }
        }
        .onChange(of: isActive) { _, active in
            if let player = player {
                if active {
                    player.play()
                } else {
                    player.pause()
                }
            }
        }
    }
}
