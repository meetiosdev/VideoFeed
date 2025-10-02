import SwiftUI
import AVFoundation

@main
struct VideoFeedApp: App {
    
    init() {
        // Configure audio session for the entire app
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            let repository = MockVideoRepository()
            let useCase = FetchManifestUseCase(repository: repository)
            let viewModel = VideoFeedViewModel(fetchManifestUseCase: useCase)
            VideoFeedView(viewModel: viewModel)
        }
    }
}
