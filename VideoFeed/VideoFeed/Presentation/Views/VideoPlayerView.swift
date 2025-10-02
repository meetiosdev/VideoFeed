import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayerView: View {
    var player: AVPlayer?
    @Binding var isActive: Bool
    var accessibilityId: Int

    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        // Configure audio session for playback
                        do {
                            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
                            try AVAudioSession.sharedInstance().setActive(true)
                        } catch {
                            print("Failed to set audio session category: \(error)")
                        }
                        
                        if isActive {
                            player.play()
                            player.isMuted = false
                        }
                        
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
                    // Ensure audio session is configured when video becomes active
                    do {
                        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
                        try AVAudioSession.sharedInstance().setActive(true)
                    } catch {
                        print("Failed to set audio session category: \(error)")
                    }
                    
                    player.play()
                    player.isMuted = false
                } else {
                    player.pause()
                }
            }
        }
    }
}
