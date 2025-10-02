import SwiftUI
import AVKit
import AVFoundation

struct VideoPlayerView: View {
    var player: AVPlayer?
    @Binding var isActive: Bool
    var accessibilityId: Int
    var videoId: String

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
                            // Clear progress when video finishes
                            VideoProgressService.shared.clearProgress(for: videoId)
                            player.seek(to: .zero)
                            player.play()
                        }
                    }
                    .onDisappear {
                        // Save progress before pausing
                        let currentTime = player.currentTime()
                        VideoProgressService.shared.saveProgress(for: videoId, time: currentTime)
                        player.pause()
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
                    // Save progress when video becomes inactive
                    let currentTime = player.currentTime()
                    VideoProgressService.shared.saveProgress(for: videoId, time: currentTime)
                    player.pause()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // Save progress when app goes to background
            if let player = player {
                let currentTime = player.currentTime()
                VideoProgressService.shared.saveProgress(for: videoId, time: currentTime)
            }
        }
    }
}
