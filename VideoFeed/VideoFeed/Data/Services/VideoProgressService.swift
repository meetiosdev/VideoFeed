import Foundation
import AVKit

class VideoProgressService {
    static let shared = VideoProgressService()
    
    private let userDefaults = UserDefaults.standard
    private let progressKey = "videoProgress"
    
    private init() {}
    
    // Store video progress
    func saveProgress(for videoId: String, time: CMTime) {
        let timeInSeconds = CMTimeGetSeconds(time)
        guard timeInSeconds.isFinite && timeInSeconds > 0 else { return }
        
        var progressDict = getProgressDictionary()
        progressDict[videoId] = timeInSeconds
        userDefaults.set(progressDict, forKey: progressKey)
    }
    
    // Retrieve video progress
    func getProgress(for videoId: String) -> CMTime? {
        let progressDict = getProgressDictionary()
        guard let timeInSeconds = progressDict[videoId] else { return nil }
        return CMTime(seconds: timeInSeconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
    }
    
    // Clear progress for a specific video
    func clearProgress(for videoId: String) {
        var progressDict = getProgressDictionary()
        progressDict.removeValue(forKey: videoId)
        userDefaults.set(progressDict, forKey: progressKey)
    }
    
    // Clear all progress
    func clearAllProgress() {
        userDefaults.removeObject(forKey: progressKey)
    }
    
    private func getProgressDictionary() -> [String: Double] {
        return userDefaults.dictionary(forKey: progressKey) as? [String: Double] ?? [:]
    }
}
