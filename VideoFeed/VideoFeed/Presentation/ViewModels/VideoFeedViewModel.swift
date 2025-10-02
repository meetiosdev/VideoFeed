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
    private let fetchManifestUseCase: FetchManifestUseCase
    
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
                player.currentItem?.preferredForwardBufferDuration = 5
                player.currentItem?.canUseNetworkResourcesForLiveStreamingWhilePaused = true
                if let item = player.currentItem {
                    statusObservers[i] = item.observe(\.status, options: [.new]) { [weak self] item, _ in
                        if item.status == .readyToPlay {
                            DispatchQueue.main.async {
                                self?.markVideoReady(at: i)
                            }
                        }
                    }
                }
            }
        }
        let keep = Set(indices)
        for key in players.keys where !keep.contains(key) {
            players[key]?.pause()
            players[key]?.replaceCurrentItem(with: nil)
            players.removeValue(forKey: key)
            statusObservers[key] = nil
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
}
