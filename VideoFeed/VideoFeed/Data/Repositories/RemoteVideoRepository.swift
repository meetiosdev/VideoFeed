import Foundation
import Combine

class RemoteVideoRepository: VideoRepository {
    private let manifestURL = APIConstants.manifestURL
    
    func fetchManifest() -> AnyPublisher<[VideoItem], Error> {
        URLSession.shared.dataTaskPublisher(for: manifestURL)
            .map(\.data)
            .decode(type: Manifest.self, decoder: JSONDecoder())
            .map { manifest in
                manifest.videos.compactMap { URL(string: $0) }
                    .map { VideoItem(id: UUID(), url: $0) }
            }
            .eraseToAnyPublisher()
    }
}
