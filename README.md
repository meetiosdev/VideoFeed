# ReelsTiktokClone
Build Instructions:
1. Open the project in Xcode. Select VideoFeed/VideoFeed.xcodeproj
2. Select the desired simulator or a connected device.
3. Run the app with Cmd+R.

To run tests:
1. Test with Cmd+U.
2. For UI tests, ensure the simulator is running.

Requirements:
Xcode 14 or later
Swift 5.7 or later
macOS 12.0 or later

Architectural Documentation: 

The app uses a Clean Architecture structure, mapped to MVVM for the presentation layer:

Domain Layer: Contains business logic (e.g., `FetchManifestUseCase`), independent of frameworks.
Data Layer: Handles data access (e.g., `MockVideoRepository, RemoteVideoRepository `), abstracts network and persistence.
Presentation Layer: SwiftUI Views and ViewModels (e.g., `VideoFeedViewModel`), manages UI state and user interaction.

This separation ensures each layer is independently testable, maintainable, and scalable.

Key Design Decisions

SwiftUI for modern, declarative, and performant UI. 
Used Combine for State Management: Ensures reactive, up-to-date UI.
Native, efficient video playback using AVPlayer.
Only a 3 videos are loaded at a time, with adaptive prefetch based on network speed.
UI blocks scrolling until the next video is ready, preventing black screens.
Player pooling and resource cleanup to prevent memory bloat.
Only upto 3 AVPlayer instances are kept alive.
Players and observers are deallocated as videos scroll out of view.
Combine cancellables to avoid leaks.
Next/previous videos are preloaded and buffered.
Videos auto-play and loop smoothly.
Uses SwiftUI’s native paging for fluid transitions.
Only initial HLS segments are loaded for prefetch.
Error handling message in text and progressview to handle errors and loading.
Out of scope: Localization, accessibility etc

Unit Tests (`VideoFeedTests/VideoFeedTests.swift`)

Test business logic and ViewModel in isolation.
Used MockVideoRepository to avoid real network calls.
testFetchManifestUpdatesVideos: Checks count of total videos is 505 if anything changed it will fail and we'll be informed by Jenkins for example. We can then acknowledge this failure by investigating it.
testMarkVideoReady: Verifies playback readiness logic.
testPrefetchPlayers: Checks prefetch logic and error handling.

UI Tests (`VideoFeedUITests/VideoFeedUITests.swift`)

 testVideoPlayerAtIndex0: Verifies the first video player appears at index 0 when app is launched we then further swipe up and check if video player with different accessibility id appears .

Attached Code Coverage screenshot 94%

Summary:
App leverages Clean Architecture and MVVM to deliver a scalable, testable, and performant infinite video feed. By combining strict separation of concerns, efficient memory management, adaptive prefetching, and comprehensive testing, the app provides a smooth, reliable user experience.



