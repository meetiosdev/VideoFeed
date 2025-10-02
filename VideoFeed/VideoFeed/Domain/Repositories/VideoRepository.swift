import Foundation
import Combine

protocol VideoRepository {
    func fetchManifest() -> AnyPublisher<[VideoItem], Error>
}

final class FetchManifestUseCase {
    private let repository: VideoRepository
    
    init(repository: VideoRepository) {
        self.repository = repository
    }
    
    func execute() -> AnyPublisher<[VideoItem], Error> {
        return repository.fetchManifest()
    }
}
