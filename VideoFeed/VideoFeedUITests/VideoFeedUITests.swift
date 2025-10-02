import XCTest

final class VideoFeedUITests: XCTestCase {

    //Checks first Video Player's accessibility id when loaded without error
    @MainActor
    func testVideoPlayerAtIndex0() throws {
        let app = XCUIApplication()
        app.launch()

        let videoPlayer = app.otherElements["Video Player 0"]
        XCTAssertTrue(videoPlayer.exists)

        app.swipeUp()

        //Swipe up then check for more indexes
        let videoPlayer2 = app.otherElements["Video Player 1"]
        XCTAssertTrue(videoPlayer2.exists)
    }
}
