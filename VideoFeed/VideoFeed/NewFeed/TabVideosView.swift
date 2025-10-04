
//
//  ContentView.swift
//  VideoFeed
//
//  Created by Swarajmeet Singh on 04/10/25.
//
//
//  ContentView.swift
//  VideoFeed
//
//  Created by Swarajmeet Singh on 04/10/25.
//

import SwiftUI
import AVKit

struct TabVideosView: View {
    @State private var viewModel = VideoViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading {
                Text("Loading")
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            } else if !viewModel.videos.isEmpty {
                TabView(selection: $viewModel.currentIndex) {
                    ForEach(Array(viewModel.videos.enumerated()), id: \.element.id) { index, video in
                        TabVideoPlayerView(video: video)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .ignoresSafeArea()
            } else {
                Text("No videos available")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }
        }
        .onAppear {
            viewModel.loadVideos()
        }
    }
}

struct TabVideoPlayerView: View {
    let video: Video
    @State private var player: AVPlayer?

    var body: some View {
        VideoPlayer(player: player)
            .onAppear {
                // Auto-play the video
                if player == nil {
                    player = AVPlayer(url: URL(string: video.url)!)
                    player?.play()
                }
            }
    }
}

#Preview {
    TabVideosView()
}
