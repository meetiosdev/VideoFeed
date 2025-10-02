import XCTest
import Combine
@testable import VideoFeed

class VideoFeedViewModelTests: XCTestCase {
    var viewModel: VideoFeedViewModel!
    var cancellables: Set<AnyCancellable> = []

    override func setUp() {
        super.setUp()
        let repository = MockVideoRepository()
        let useCase = FetchManifestUseCase(repository: repository)
        viewModel = VideoFeedViewModel(fetchManifestUseCase: useCase)
    }

    func testFetchManifestUpdatesVideos() {
        let expectation = self.expectation(description: "Videos loaded")
        viewModel.$videos
            .dropFirst() 
            .sink { videos in
                if videos.count == 505 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(viewModel.videos.count, 505)
    }

    func testMarkVideoReady() {
        viewModel.videoReadyStates = [false, false]
        viewModel.markVideoReady(at: 1)
        XCTAssertTrue(viewModel.videoReadyStates[1])
    }

    func testPrefetchPlayers() {
        viewModel.videoReadyStates = [false, false, false]
        viewModel.prefetchPlayers(around: 1)
        XCTAssertNil(viewModel.error)
    }

    func testOnPageChangePrefetchesPlayers() {
        viewModel.videoReadyStates = [false, false, false]
        viewModel.onPageChange(to: 2)
        XCTAssertTrue(viewModel.isLoading)
    }
}
