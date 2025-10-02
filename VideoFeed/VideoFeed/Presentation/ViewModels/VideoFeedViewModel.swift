import Foundation
import Combine
import AVKit

class VideoFeedViewModel: ObservableObject {
    @Published var videos: [VideoItem] = []
    @Published var currentIndex: Int = 0
    @Published var isLoading: Bool = false
    @Published var error: String?
    @Published var videoReadyStates: [Bool] = []
    @Published var players: [Int: AVPlayer] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    private var statusObservers: [Int: NSKeyValueObservation] = [:]
    private var timeObservers: [Int: Any] = [:]
    private let fetchManifestUseCase: FetchManifestUseCase
    private let progressService = VideoProgressService.shared
    
    init(fetchManifestUseCase: FetchManifestUseCase) {
        self.fetchManifestUseCase = fetchManifestUseCase
        fetchVideos()
    }
    
    func fetchVideos() {
        isLoading = true
        fetchManifestUseCase.execute()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let err) = completion {
                    self?.error = err.localizedDescription
                }
            }, receiveValue: { [weak self] items in
                self?.videos = items
                self?.videoReadyStates = Array(repeating: false, count: items.count)
                self?.prefetchPlayers(around: 0)
            })
            .store(in: &cancellables)
    }
    
    func markVideoReady(at index: Int) {
        guard videoReadyStates.indices.contains(index) else { return }
        videoReadyStates[index] = true
    }
    
    func prefetchPlayers(around index: Int) {
        let indices = [index - 1, index, index + 1].filter { videos.indices.contains($0) }
        for i in indices {
            if players[i] == nil {
                let player = AVPlayer(url: videos[i].url)
                players[i] = player
                player.isMuted = false
                player.currentItem?.preferredForwardBufferDuration = 5
                player.currentItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = true
                
                // Restore progress if available
                if let savedProgress = progressService.getProgress(for: videos[i].progressId) {
                    player.seek(to: savedProgress)
                }
                
                if let item = player.currentItem {
                    statusObservers[i] = item.observe(\.status, options: [.new]) { [weak self] item, _ in
                        if item.status == .readyToPlay {
                            DispatchQueue.main.async {
                                self?.markVideoReady(at: i)
                            }
                        }
                    }
                    
                    // Add time observer for progress tracking
                    let timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)), queue: .main) { [weak self] time in
                        self?.progressService.saveProgress(for: self?.videos[i].progressId ?? "", time: time)
                    }
                    timeObservers[i] = timeObserver
                }
            }
        }
        let keep = Set(indices)
        for key in players.keys where !keep.contains(key) {
            // Save final progress before cleanup
            if let player = players[key] {
                let currentTime = player.currentTime()
                progressService.saveProgress(for: videos[key].progressId, time: currentTime)
            }
            
            players[key]?.pause()
            players[key]?.replaceCurrentItem(with: nil)
            players.removeValue(forKey: key)
            statusObservers[key] = nil
            
            // Remove time observer
            if let timeObserver = timeObservers[key] {
                players[key]?.removeTimeObserver(timeObserver)
                timeObservers.removeValue(forKey: key)
            }
            
            if videoReadyStates.indices.contains(key) {
                videoReadyStates[key] = false
            }
        }
    }
    
    func onPageChange(to index: Int) {
        prefetchPlayers(around: index)
    }
    
    func player(for index: Int) -> AVPlayer? {
        players[index]
    }
    
    // Clear progress for a specific video
    func clearProgress(for index: Int) {
        guard videos.indices.contains(index) else { return }
        progressService.clearProgress(for: videos[index].progressId)
    }
    
    // Clear all progress
    func clearAllProgress() {
        progressService.clearAllProgress()
    }
}
