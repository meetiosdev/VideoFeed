import SwiftUI

struct VideoFeedView: View {
    @StateObject var viewModel: VideoFeedViewModel

    var body: some View {
        if viewModel.isLoading {
            ProgressView("Loading...")
        } else if let error = viewModel.error {
            Text("Error: \(error)")
        } else {
            TabView(selection: $viewModel.currentIndex) {
                ForEach(Array(viewModel.videos.enumerated()), id: \.element.id) { index, video in
                    VideoPlayerView(
                        player: viewModel.player(for: index),
                        isActive: .constant(viewModel.currentIndex == index),
                        accessibilityId: index
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .background(Color.black)
            .ignoresSafeArea()
            .onChange(of: viewModel.currentIndex) { _, newIndex in
                viewModel.onPageChange(to: newIndex)
            }
        }
    }
}

// Safe subscript extension remains unchanged
extension Array {
    subscript(safe index: Int, default defaultValue: Element) -> Element {
        indices.contains(index) ? self[index] : defaultValue
    }
}
