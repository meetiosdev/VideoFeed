//
//  VideoViewModel.swift
//  VideoFeed
//
//  Created by Swarajmeet Singh on 04/10/25.
//

import Foundation
import Combine

struct Video: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    let url: String
}

@Observable
class VideoViewModel {
    var videos: [Video] = []
    var currentIndex: Int = 0
    var selectedVideo: Video?
    var isLoading: Bool = false
    var errorMessage: String?

    init() {
        loadVideos()
    }

    func loadVideos() {
        isLoading = true
        errorMessage = nil
        
        // Simulate async loading; in a real app, this could fetch from API
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.videos = [
                Video(
                    id: UUID(uuidString: "9727e220-1d58-4c00-466a-a26ff7941de4")!,
                    name: "Fire works",
                    url: "https://videos.pexels.com/video-files/8243096/8243096-hd_720_1280_30fps.mp4"
                ),
                Video(
                    id: UUID(uuidString: "8727e220-0d58-4c00-966a-a26ff7941de5")!,
                    name: "For Bigger Blazes",
                    url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"
                ),
                Video(
                    id: UUID(uuidString: "6669ed27-9169-4e92-a4ec-ffd6eb55bd61")!,
                    name: "For Bigger Escapes",
                    url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4"
                ),
                Video(
                    id: UUID(uuidString: "54f934b5-4a79-41fb-9312-1d7721a3c6ea")!,
                    name: "For Bigger Fun",
                    url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4"
                ),
                Video(
                    id: UUID(uuidString: "12e34798-8881-4d14-ab08-739d704d369e")!,
                    name: "For Bigger Joyrides",
                    url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4"
                ),
                Video(
                    id: UUID(uuidString: "3d8683ab-8d25-4aef-a8fc-72d1ce0a6f9a")!,
                    name: "For Bigger Meltdowns",
                    url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerMeltdowns.mp4"
                ),
                Video(
                    id: UUID(uuidString: "d6c7dad6-09b8-43ce-b2a4-4bae52f71412")!,
                    name: "We Are Going On Bullrun",
                    url: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/WeAreGoingOnBullrun.mp4"
                ),
                Video(
                    id: UUID(uuidString: "0495be4f-5df4-430c-a0f8-670877bc7018")!,
                    name: "Big Buck Bunny Trailer",
                    url: "http://docs.evostream.com/sample_content/assets/bun33s.mp4"
                ),
                Video(
                    id: UUID(uuidString: "b738f0c2-b060-48ce-805e-c91259eaef0a")!,
                    name: "Sintel 1 Minute Clip",
                    url: "http://docs.evostream.com/sample_content/assets/sintel1m720p.mp4"
                )
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
