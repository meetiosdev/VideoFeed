


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
    
    // MARK: - Private Properties
    
    /// Combine cancellables for managing async operations
    private var cancellables = Set<AnyCancellable>()
    
    /// Use case for fetching video manifest data
    private let fetchManifestUseCase: FetchManifestUseCase
    
    /// Shared service for video prefetching and player management
    private let prefetchService = VideoPrefetchService.shared
    
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
        prefetchService.prefetchForVideoFeed(videos: videos, currentIndex: index)
    }
    
    /// Get the AVPlayer instance for a specific video index
    /// - Parameter index: Video index
    /// - Returns: AVPlayer instance if available, nil otherwise
    func player(for index: Int) -> AVPlayer? {
        guard videos.indices.contains(index) else { return nil }
        return prefetchService.getPlayer(for: videos[index].progressId)
    }
    
    // MARK: - Private Methods
    
    /// Handle successfully received video items
    /// - Parameter items: Array of video items from the manifest
    private func handleVideosReceived(_ items: [VideoItem]) {
        videos = items
        prefetchService.prefetchForVideoFeed(videos: items, currentIndex: 0)
    }
}
