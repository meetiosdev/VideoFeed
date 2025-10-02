import SwiftUI

@main
struct VideoFeedApp: App {
    var body: some Scene {
        WindowGroup {
            let repository = MockVideoRepository()
            let useCase = FetchManifestUseCase(repository: repository)
            let viewModel = VideoFeedViewModel(fetchManifestUseCase: useCase)
            VideoFeedView(viewModel: viewModel)
        }
    }
}
