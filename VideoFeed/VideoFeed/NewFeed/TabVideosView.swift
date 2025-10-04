
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
                ProgressView("Loading videos...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            } else {
                TabView(selection: $viewModel.currentIndex) {
                    ForEach(Array(viewModel.videos.enumerated()), id: \.element.id) { index, video in
                        TabVideoPlayerView(video: video)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
        .ignoresSafeArea()
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
