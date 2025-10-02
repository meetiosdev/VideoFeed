import Foundation
import Combine

class MockVideoRepository: VideoRepository {
    var videos: [VideoItem] = []
    
    func fetchManifest() -> AnyPublisher<[VideoItem], any Error> {
        guard let url = Bundle.main.url(forResource: "manifest", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let manifest = try? JSONDecoder().decode(Manifest.self, from: data) else {
            return Just([])
                .setFailureType(to: Error.self)
                .eraseToAnyPublisher()
        }
        let videos = manifest.videos.compactMap { URL(string: $0) }
            .map { VideoItem(id: UUID(), url: $0) }
        print(videos.count)
        return Just(videos)
            .setFailureType(to: Error.self)
            .eraseToAnyPublisher()
    }
}
