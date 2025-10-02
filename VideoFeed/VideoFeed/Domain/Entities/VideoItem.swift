import Foundation

struct VideoItem {
    let id: UUID
    let url: URL
    
    // Generate a unique identifier for progress tracking
    var progressId: String {
        return url.absoluteString
    }
}
