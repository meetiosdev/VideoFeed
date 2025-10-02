import SwiftUI
import AVKit
import AVFoundation
import ObjectiveC

struct VideoPlayerView: View {
    var player: AVPlayer?
    @Binding var isActive: Bool
    var accessibilityId: Int
    var videoId: String
    
    @State private var isLoading = true

    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .onAppear {
                        print("🎥 VideoPlayerView onAppear - Video ID: \(videoId), Accessibility ID: \(accessibilityId)")
                        
                        // Reset loading state when view appears
                        isLoading = true
                        print("🔄 Reset loading state to true for video: \(videoId)")
                        
                        // Configure audio session for playback
                        do {
                            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
                            try AVAudioSession.sharedInstance().setActive(true)
                            print("🔊 Audio session configured successfully for video: \(videoId)")
                        } catch {
                            print("❌ Failed to set audio session category for video \(videoId): \(error)")
                        }
                        
                        // Add observer for player item status
                        if let currentItem = player.currentItem {
                            print("📹 Setting up player item observer for video: \(videoId)")
                            
                            // Check if video is already ready
                            if currentItem.status == .readyToPlay {
                                print("✅ Video already ready to play - ID: \(videoId)")
                                isLoading = false
                                print("🔄 Loading state set to false (already ready) for video: \(videoId)")
                            }
                            
                            // Observe player item status
                            let statusObserver = currentItem.observe(\.status, options: [.new]) { item, _ in
                                switch item.status {
                                case .readyToPlay:
                                    print("✅ Video loaded and ready to play - ID: \(videoId)")
                                    DispatchQueue.main.async {
                                        isLoading = false
                                        print("🔄 Loading state set to false for video: \(videoId)")
                                    }
                                case .failed:
                                    print("❌ Video failed to load - ID: \(videoId), Error: \(item.error?.localizedDescription ?? "Unknown error")")
                                    DispatchQueue.main.async {
                                        isLoading = false
                                        print("🔄 Loading state set to false (failed) for video: \(videoId)")
                                    }
                                case .unknown:
                                    print("⏳ Video status unknown - ID: \(videoId)")
                                @unknown default:
                                    print("❓ Unknown video status - ID: \(videoId)")
                                }
                            }
                            
                            // Store observer to prevent deallocation
                            objc_setAssociatedObject(player, "statusObserver", statusObserver, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                        }
                        
                        if isActive {
                            print("▶️ Starting playback for active video: \(videoId)")
                            player.play()
                            player.isMuted = false
                        } else {
                            print("⏸️ Video loaded but not active: \(videoId)")
                        }
                        
                        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                            print("🏁 Video finished playing - ID: \(videoId)")
                            // Clear progress when video finishes
                            VideoProgressService.shared.clearProgress(for: videoId)
                            player.seek(to: .zero)
                            player.play()
                        }
                    }
                    .onDisappear {
                        print("👋 VideoPlayerView onDisappear - Video ID: \(videoId)")
                        // Save progress before pausing
                        let currentTime = player.currentTime()
                        let timeInSeconds = CMTimeGetSeconds(currentTime)
                        print("💾 Saving progress for video \(videoId) at \(String(format: "%.2f", timeInSeconds)) seconds")
                        VideoProgressService.shared.saveProgress(for: videoId, time: currentTime)
                        player.pause()
                    }
                    .accessibilityLabel("Video Player \(accessibilityId)")
            } else {
                ProgressView()
            }
            
            // Loading overlay
            if isLoading {
                Color.red
                    .ignoresSafeArea()
                    .overlay(
                        VStack(spacing: 20) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.5)
                            
                            Text("Loading video...")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                    )
                    .onAppear {
                        print("🔴 Red loading overlay appeared for video: \(videoId)")
                    }
                    .onDisappear {
                        print("🔴 Red loading overlay disappeared for video: \(videoId)")
                    }
            }
        }
        .onChange(of: isActive) { _, active in
            if let player = player {
                if active {
                    print("🔄 Video became active - ID: \(videoId)")
                    // Ensure audio session is configured when video becomes active
                    do {
                        try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
                        try AVAudioSession.sharedInstance().setActive(true)
                        print("🔊 Audio session reconfigured for active video: \(videoId)")
                    } catch {
                        print("❌ Failed to set audio session category for active video \(videoId): \(error)")
                    }
                    
                    player.play()
                    player.isMuted = false
                    print("▶️ Started playing active video: \(videoId)")
                } else {
                    print("🔄 Video became inactive - ID: \(videoId)")
                    // Save progress when video becomes inactive
                    let currentTime = player.currentTime()
                    let timeInSeconds = CMTimeGetSeconds(currentTime)
                    print("💾 Saving progress for inactive video \(videoId) at \(String(format: "%.2f", timeInSeconds)) seconds")
                    VideoProgressService.shared.saveProgress(for: videoId, time: currentTime)
                    player.pause()
                    print("⏸️ Paused inactive video: \(videoId)")
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // Save progress when app goes to background
            if let player = player {
                let currentTime = player.currentTime()
                let timeInSeconds = CMTimeGetSeconds(currentTime)
                print("📱 App going to background - saving progress for video \(videoId) at \(String(format: "%.2f", timeInSeconds)) seconds")
                VideoProgressService.shared.saveProgress(for: videoId, time: currentTime)
            }
        }
    }
}
