import Foundation
import AVKit
import Combine

/// Shared service for managing video prefetching and player lifecycle
/// Implements sliding window prefetching strategy for optimal performance
class VideoPrefetchService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = VideoPrefetchService()
    
    // MARK: - Published Properties
    
    /// Dictionary of preloaded AVPlayer instances
    @Published var players: [String: AVPlayer] = [:]
    
    // MARK: - Private Properties
    
    /// Time observers for progress tracking
    private var timeObservers: [String: Any] = [:]
    
    /// Status observers for player readiness
    private var statusObservers: [String: NSKeyValueObservation] = [:]
    
    /// Service for persisting and retrieving video playback progress
    private let progressService = VideoProgressService.shared
    
    /// Current prefetch window (indices being kept in memory)
    private var currentPrefetchWindow: Set<String> = []
    
    /// Maximum number of players to keep in memory
    private let maxPlayers: Int = 3
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Prefetch players around a specific video ID using sliding window strategy
    /// - Parameters:
    ///   - videoId: Center video ID for prefetching
    ///   - videos: Array of all available videos
    ///   - currentIndex: Current index of the center video
    func prefetchPlayers(around videoId: String, videos: [VideoItem], currentIndex: Int) {
        let prefetchIds = calculatePrefetchIds(around: currentIndex, videos: videos)
        let prefetchSet = Set(prefetchIds)
        
        // Create new players for IDs that don't have them
        createPlayersForIds(prefetchIds, videos: videos)
        
        // Clean up players that are no longer needed
        cleanupUnusedPlayers(keeping: prefetchSet)
        
        // Update current window
        currentPrefetchWindow = prefetchSet
    }
    
    /// Get a preloaded player for a specific video ID
    /// - Parameter videoId: Video ID to get player for
    /// - Returns: AVPlayer instance if available, nil otherwise
    func getPlayer(for videoId: String) -> AVPlayer? {
        return players[videoId]
    }
    
    /// Create a single player for immediate use
    /// - Parameters:
    ///   - videoId: Video ID
    ///   - video: Video item
    /// - Returns: Configured AVPlayer instance
    func createPlayer(for videoId: String, video: VideoItem) -> AVPlayer {
        let player = createConfiguredPlayer(for: video)
        players[videoId] = player
        
        setupPlayerObservers(for: player, videoId: videoId)
        restoreVideoProgress(for: player, videoId: videoId)
        
        return player
    }
    
    /// Clean up all players and resources
    func cleanupAllPlayers() {
        for videoId in players.keys {
            cleanupPlayer(for: videoId)
        }
        players.removeAll()
        timeObservers.removeAll()
        statusObservers.removeAll()
        currentPrefetchWindow.removeAll()
    }
    
    /// Clean up a specific player
    /// - Parameter videoId: Video ID to clean up
    func cleanupPlayer(for videoId: String) {
        guard let player = players[videoId] else { return }
        
        // Save final progress before cleanup
        let currentTime = player.currentTime()
        progressService.saveProgress(for: videoId, time: currentTime)
        
        // Clean up player resources
        player.pause()
        player.replaceCurrentItem(with: nil)
        
        // Remove observers
        if let timeObserver = timeObservers[videoId] {
            player.removeTimeObserver(timeObserver)
            timeObservers.removeValue(forKey: videoId)
        }
        
        if let statusObserver = statusObservers[videoId] {
            statusObserver.invalidate()
            statusObservers.removeValue(forKey: videoId)
        }
        
        // Update state
        players.removeValue(forKey: videoId)
        currentPrefetchWindow.remove(videoId)
    }
    
    /// Get current prefetch window for debugging
    /// - Returns: Set of video IDs currently in memory
    func getCurrentPrefetchWindow() -> Set<String> {
        return currentPrefetchWindow
    }
    
    /// Get memory usage statistics
    /// - Returns: Dictionary with memory usage info
    func getMemoryStats() -> [String: Any] {
        return [
            "activePlayers": players.count,
            "maxPlayers": maxPlayers,
            "prefetchWindow": Array(currentPrefetchWindow),
            "memoryEfficiency": players.count <= maxPlayers ? "Optimal" : "Overloaded"
        ]
    }
    
    // MARK: - Private Methods
    
    /// Calculate which video IDs should have preloaded players
    /// - Parameters:
    ///   - currentIndex: Center index
    ///   - videos: Array of all videos
    /// - Returns: Array of video IDs to prefetch
    private func calculatePrefetchIds(around currentIndex: Int, videos: [VideoItem]) -> [String] {
        let indices = [currentIndex - 1, currentIndex, currentIndex + 1]
            .filter { videos.indices.contains($0) }
        
        return indices.map { videos[$0].progressId }
    }
    
    /// Create and configure AVPlayer instances for the specified video IDs
    /// - Parameters:
    ///   - videoIds: Array of video IDs to create players for
    ///   - videos: Array of all videos
    private func createPlayersForIds(_ videoIds: [String], videos: [VideoItem]) {
        for videoId in videoIds {
            guard players[videoId] == nil else { continue }
            
            guard let video = videos.first(where: { $0.progressId == videoId }) else { continue }
            
            let player = createConfiguredPlayer(for: video)
            players[videoId] = player
            
            setupPlayerObservers(for: player, videoId: videoId)
            restoreVideoProgress(for: player, videoId: videoId)
        }
    }
    
    /// Create and configure an AVPlayer instance for a specific video
    /// - Parameter video: Video item
    /// - Returns: Configured AVPlayer instance
    private func createConfiguredPlayer(for video: VideoItem) -> AVPlayer {
        let player = AVPlayer(url: video.url)
        
        // Configure player for optimal performance
        player.isMuted = false
        player.currentItem?.preferredForwardBufferDuration = 5
        player.currentItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = true
        
        return player
    }
    
    /// Setup observers for progress tracking and status monitoring
    /// - Parameters:
    ///   - player: AVPlayer instance to observe
    ///   - videoId: Video ID for this player
    private func setupPlayerObservers(for player: AVPlayer, videoId: String) {
        // Setup periodic time observer for progress tracking
        let timeObserver = player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { [weak self] time in
            self?.saveVideoProgress(videoId: videoId, time: time)
        }
        timeObservers[videoId] = timeObserver
        
        // Setup status observer for player readiness
        if let currentItem = player.currentItem {
            let statusObserver = currentItem.observe(\.status, options: [.new]) { [weak self] item, _ in
                DispatchQueue.main.async {
                    self?.handlePlayerStatusChange(videoId: videoId, status: item.status)
                }
            }
            statusObservers[videoId] = statusObserver
        }
    }
    
    /// Handle player status changes
    /// - Parameters:
    ///   - videoId: Video ID
    ///   - status: New player status
    private func handlePlayerStatusChange(videoId: String, status: AVPlayerItem.Status) {
        switch status {
        case .readyToPlay:
            // Player is ready, could notify observers if needed
            break
        case .failed:
            // Handle failure, could retry or show error
            print("Player failed for video: \(videoId)")
        case .unknown:
            // Still loading
            break
        @unknown default:
            break
        }
    }
    
    /// Restore saved playback progress for a video
    /// - Parameters:
    ///   - player: AVPlayer instance
    ///   - videoId: Video ID
    private func restoreVideoProgress(for player: AVPlayer, videoId: String) {
        if let savedProgress = progressService.getProgress(for: videoId) {
            player.seek(to: savedProgress)
        }
    }
    
    /// Save current playback progress for a video
    /// - Parameters:
    ///   - videoId: Video ID
    ///   - time: Current playback time
    private func saveVideoProgress(videoId: String, time: CMTime) {
        progressService.saveProgress(for: videoId, time: time)
    }
    
    /// Clean up unused player instances to free memory
    /// - Parameter keep: Set of video IDs to keep players for
    private func cleanupUnusedPlayers(keeping keep: Set<String>) {
        for videoId in players.keys where !keep.contains(videoId) {
            cleanupPlayer(for: videoId)
        }
    }
}

// MARK: - VideoPrefetchService + Convenience Methods

extension VideoPrefetchService {
    
    /// Prefetch players for a video feed with automatic index calculation
    /// - Parameters:
    ///   - videos: Array of all videos
    ///   - currentIndex: Current active index
    func prefetchForVideoFeed(videos: [VideoItem], currentIndex: Int) {
        guard !videos.isEmpty, videos.indices.contains(currentIndex) else { return }
        
        let currentVideoId = videos[currentIndex].progressId
        prefetchPlayers(around: currentVideoId, videos: videos, currentIndex: currentIndex)
    }
    
    /// Check if a player is ready for a specific video
    /// - Parameter videoId: Video ID to check
    /// - Returns: True if player exists and is ready
    func isPlayerReady(for videoId: String) -> Bool {
        guard let player = players[videoId] else { return false }
        return player.currentItem?.status == .readyToPlay
    }
    
    /// Get all ready players
    /// - Returns: Dictionary of ready players
    func getReadyPlayers() -> [String: AVPlayer] {
        return players.filter { isPlayerReady(for: $0.key) }
    }
    
    /// Force prefetch a specific video (useful for user-initiated prefetching)
    /// - Parameters:
    ///   - videoId: Video ID to prefetch
    ///   - video: Video item
    func forcePrefetch(videoId: String, video: VideoItem) {
        guard players[videoId] == nil else { return }
        
        let player = createConfiguredPlayer(for: video)
        players[videoId] = player
        
        setupPlayerObservers(for: player, videoId: videoId)
        restoreVideoProgress(for: player, videoId: videoId)
        
        currentPrefetchWindow.insert(videoId)
    }
}
