


import Foundation
import Combine
import AVKit

/// ViewModel responsible for managing video feed data, player instances, and playback state
/// Handles video prefetching, progress tracking, and memory management for optimal performance
class VideoFeedViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Array of video items to be displayed in the feed
    @Published var videos: [VideoItem] = []
    
    /// Currently active video index in the feed
    @Published var currentIndex: Int = 0
    
    /// Loading state for video manifest fetching
    @Published var isLoading: Bool = false
    
    /// Error message if video loading fails
    @Published var error: String?
    
    /// Dictionary of preloaded AVPlayer instances for smooth scrolling performance
    @Published var players: [Int: AVPlayer] = [:]
    
    // MARK: - Private Properties
    
    /// Combine cancellables for managing async operations
    private var cancellables = Set<AnyCancellable>()
    
    /// Time observers for periodic progress tracking
    private var timeObservers: [Int: Any] = [:]
    
    /// Use case for fetching video manifest data
    private let fetchManifestUseCase: FetchManifestUseCase
    
    /// Service for persisting and retrieving video playback progress
    private let progressService = VideoProgressService.shared
    
    // MARK: - Initialization
    
    /// Initialize the ViewModel with required dependencies
    /// - Parameter fetchManifestUseCase: Use case for fetching video manifest
    init(fetchManifestUseCase: FetchManifestUseCase) {
        self.fetchManifestUseCase = fetchManifestUseCase
        fetchVideos()
    }
    
    // MARK: - Public Methods
    
    /// Fetch video manifest and initialize the feed
    /// Automatically prefetches the first video for immediate playback
    func fetchVideos() {
        isLoading = true
        error = nil
        
        fetchManifestUseCase.execute()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isLoading = false
                    if case .failure(let error) = completion {
                        self?.error = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] items in
                    self?.handleVideosReceived(items)
                }
            )
            .store(in: &cancellables)
    }
    
    /// Handle page change events and manage player prefetching
    /// - Parameter index: New active video index
    func onPageChange(to index: Int) {
        currentIndex = index
        prefetchPlayers(around: index)
    }
    
    /// Get the AVPlayer instance for a specific video index
    /// - Parameter index: Video index
    /// - Returns: AVPlayer instance if available, nil otherwise
    func player(for index: Int) -> AVPlayer? {
        return players[index]
    }
    
    // MARK: - Private Methods
    
    /// Handle successfully received video items
    /// - Parameter items: Array of video items from the manifest
    private func handleVideosReceived(_ items: [VideoItem]) {
        videos = items
        prefetchPlayers(around: 0)
    }
    
    /// Prefetch AVPlayer instances around the current index for smooth scrolling
    /// Implements a sliding window approach to keep 3 players in memory (previous, current, next)
    /// - Parameter index: Center index for prefetching
    private func prefetchPlayers(around index: Int) {
        let prefetchIndices = calculatePrefetchIndices(around: index)
        
        // Create new players for indices that don't have them
        createPlayersForIndices(prefetchIndices)
        
        // Clean up players that are no longer needed
        cleanupUnusedPlayers(keeping: Set(prefetchIndices))
    }
    
    /// Calculate which video indices should have preloaded players
    /// - Parameter index: Center index
    /// - Returns: Array of indices to prefetch
    private func calculatePrefetchIndices(around index: Int) -> [Int] {
        return [index - 1, index, index + 1].filter { videos.indices.contains($0) }
    }
    
    /// Create and configure AVPlayer instances for the specified indices
    /// - Parameter indices: Array of indices to create players for
    private func createPlayersForIndices(_ indices: [Int]) {
        for index in indices {
            guard players[index] == nil else { continue }
            
            let player = createConfiguredPlayer(for: index)
            players[index] = player
            
            setupPlayerObservers(for: player, at: index)
            restoreVideoProgress(for: player, at: index)
        }
    }
    
    /// Create and configure an AVPlayer instance for a specific video
    /// - Parameter index: Video index
    /// - Returns: Configured AVPlayer instance
    private func createConfiguredPlayer(for index: Int) -> AVPlayer {
        let player = AVPlayer(url: videos[index].url)
        
        // Configure player for optimal performance
        player.isMuted = false
        player.currentItem?.preferredForwardBufferDuration = 5
        player.currentItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        
        return player
    }
    
    /// Setup observers for progress tracking
    /// - Parameters:
    ///   - player: AVPlayer instance to observe
    ///   - index: Video index for this player
    private func setupPlayerObservers(for player: AVPlayer, at index: Int) {
        // Setup periodic time observer for progress tracking
        let timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { [weak self] time in
            self?.saveVideoProgress(at: index, time: time)
        }
        timeObservers[index] = timeObserver
    }
    
    /// Restore saved playback progress for a video
    /// - Parameters:
    ///   - player: AVPlayer instance
    ///   - index: Video index
    private func restoreVideoProgress(for player: AVPlayer, at index: Int) {
        if let savedProgress = progressService.getProgress(for: videos[index].progressId) {
            player.seek(to: savedProgress)
        }
    }
    
    /// Save current playback progress for a video
    /// - Parameters:
    ///   - index: Video index
    ///   - time: Current playback time
    private func saveVideoProgress(at index: Int, time: CMTime) {
        progressService.saveProgress(for: videos[index].progressId, time: time)
    }
    
    /// Clean up unused player instances to free memory
    /// - Parameter keep: Set of indices to keep players for
    private func cleanupUnusedPlayers(keeping keep: Set<Int>) {
        for key in players.keys where !keep.contains(key) {
            cleanupPlayer(at: key)
        }
    }
    
    /// Clean up a specific player instance and its associated resources
    /// - Parameter index: Index of the player to clean up
    private func cleanupPlayer(at index: Int) {
        guard let player = players[index] else { return }
        
        // Save final progress before cleanup
        let currentTime = player.currentTime()
        progressService.saveProgress(for: videos[index].progressId, time: currentTime)
        
        // Clean up player resources
        player.pause()
        player.replaceCurrentItem(with: nil)
        
        // Remove observers
        if let timeObserver = timeObservers[index] {
            player.removeTimeObserver(timeObserver)
            timeObservers.removeValue(forKey: index)
        }
        
        // Update state
        players.removeValue(forKey: index)
    }
}
