//
//  Video.swift
//  VideoFeed
//
//  Created by Swarajmeet Singh on 04/10/25.
//


import Foundation
import SwiftUI

struct Video: Codable, Identifiable {
    let id: Int
    let name: String
    let url: String
}

@MainActor
class VideoViewModel: ObservableObject {
    @Published var videos: [Video] = []
    @Published var selectedVideo: Video?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    init() {
        loadVideos()
    }

    func loadVideos() {
        isLoading = true
        errorMessage = nil
        
        // Simulate async loading; in a real app, this could fetch from API
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.videos = [
                Video(id: 1, name: "For Bigger Blazes", url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"),
                Video(id: 2, name: "For Bigger Escapes", url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4"),
                Video(id: 3, name: "For Bigger Fun", url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4"),
                Video(id: 4, name: "For Bigger Joyrides", url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4"),
                Video(id: 5, name: "For Bigger Meltdowns", url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4"),
                Video(id: 6, name: "We Are Going On Bullrun", url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4"),
                Video(id: 7, name: "Ocean with Audio", url: "https://filesamples.com/samples/video/mp4/sample_960x400_ocean_with_audio.mp4"),
                Video(id: 8, name: "Sample 640x360", url: "https://filesamples.com/samples/video/mp4/sample_640x360.mp4"),
                Video(id: 9, name: "Sample 960x540", url: "https://filesamples.com/samples/video/mp4/sample_960x540.mp4"),
                Video(id: 10, name: "Sample 1280x720", url: "https://filesamples.com/samples/video/mp4/sample_1280x720.mp4"),
                Video(id: 11, name: "Sample 1920x1080", url: "https://filesamples.com/samples/video/mp4/sample_1920x1080.mp4"),
                Video(id: 12, name: "Sample 2560x1440", url: "https://filesamples.com/samples/video/mp4/sample_2560x1440.mp4"),
                Video(id: 13, name: "Sample 3840x2160", url: "https://filesamples.com/samples/video/mp4/sample_3840x2160.mp4"),
                Video(id: 14, name: "Big Buck Bunny Trailer", url: "http://docs.evostream.com/sample_content/assets/bun33s.mp4"),
                Video(id: 15, name: "Sintel 1 Minute Clip", url: "http://docs.evostream.com/sample_content/assets/sintel1m720p.mp4")
            ]
            self?.isLoading = false
        }
    }

    func selectVideo(_ video: Video) {
        selectedVideo = video
    }

    func clearSelection() {
        selectedVideo = nil
    }
}