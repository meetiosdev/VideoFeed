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
            videoPlayerView
            loadingOverlay
        }
        .onChange(of: isActive) { _, active in
            handleActiveStateChange(active)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            saveProgress()
        }
    }
    
    // MARK: - Video Player View
    @ViewBuilder
    private var videoPlayerView: some View {
        if let player = player {
            VideoPlayer(player: player)
                .onAppear {
                    setupVideoPlayer(player)
                }
                .onDisappear {
                    handleViewDisappear(player)
                }
                .accessibilityLabel("Video Player \(accessibilityId)")
        } else {
            ProgressView()
        }
    }
    
    // MARK: - Loading Overlay
    @ViewBuilder
    private var loadingOverlay: some View {
        if isLoading {
            Color.red
                .ignoresSafeArea()
                .overlay(loadingContent)
        }
    }
    
    private var loadingContent: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(1.5)
            
            Text("Loading video...")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Private Methods
    
    private func setupVideoPlayer(_ player: AVPlayer) {
        isLoading = true
        configureAudioSession()
        setupPlayerObservers(player)
        handleInitialPlaybackState(player)
        setupEndTimeObserver(player)
    }
    
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // Audio session configuration failed
            print(error.localizedDescription)
        }
    }
    
    private func setupPlayerObservers(_ player: AVPlayer) {
        guard let currentItem = player.currentItem else { return }
        
        // Check if video is already ready
        if currentItem.status == .readyToPlay {
            isLoading = false
        }
        
        // Observe player item status
        let statusObserver = currentItem.observe(\.status, options: [.new]) { item, _ in
            DispatchQueue.main.async {
                switch item.status {
                case .readyToPlay, .failed:
                    isLoading = false
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        }
        
        // Store observer to prevent deallocation
        objc_setAssociatedObject(player, "statusObserver", statusObserver, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    private func handleInitialPlaybackState(_ player: AVPlayer) {
        if isActive {
            player.play()
            player.isMuted = false
        }
    }
    
    private func setupEndTimeObserver(_ player: AVPlayer) {
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            VideoProgressService.shared.clearProgress(for: videoId)
            player.seek(to: .zero)
            player.play()
        }
    }
    
    private func handleViewDisappear(_ player: AVPlayer) {
        saveProgress()
        player.pause()
    }
    
    private func handleActiveStateChange(_ active: Bool) {
        guard let player = player else { return }
        
        if active {
            configureAudioSession()
            player.play()
            player.isMuted = false
        } else {
            saveProgress()
            player.pause()
        }
    }
    
    private func saveProgress() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        VideoProgressService.shared.saveProgress(for: videoId, time: currentTime)
    }
}
