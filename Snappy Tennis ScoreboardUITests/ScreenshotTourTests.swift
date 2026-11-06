//
//  ScreenshotTourTests.swift
//  Snappy Tennis ScoreboardUITests
//
//  Drives the Companion App through its key screens and keeps a screenshot of each,
//  for review rather than comparison. Run them with scripts/screenshots.sh --companion.
//

import XCTest

@MainActor
final class ScreenshotTourTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDown() {
        XCUIDevice.shared.orientation = .portrait
        super.tearDown()
    }

    // MARK: - Tour

    func test01MidMatch() {
        launch()
        snap("01-new-match")

        // Player 1 takes the first set 6-3, then it's 3-3 in the second, 30-15
        winGames(.player1, 4)
        winGames(.player2, 3)
        winGames(.player1, 2)
        winGames(.player2, 3)
        winGames(.player1, 3)
        tap(.player1, times: 2)
        tap(.player2)
        waitForCelebration()
        snap("02-mid-match")

        XCUIDevice.shared.orientation = .landscapeLeft
        Thread.sleep(forTimeInterval: 1)  // rotation animation
        snap("03-mid-match-landscape")
    }

    func test04MatchResult() {
        launch()
        winGames(.player1, 12)
        XCTAssertTrue(element("button.playOn").waitForExistence(timeout: 5), "Match result not shown")
        snap("04-match-result")
    }

    func test05NewMatch() {
        launch()
        element("button.newMatch").tap()
        XCTAssertTrue(element("button.start").waitForExistence(timeout: 3), "New Match screen not shown")
        Thread.sleep(forTimeInterval: 0.5)  // sheet animation
        snap("05-new-match-setup")
    }

    // MARK: - Helpers

    private enum Side: String {
        case player1 = "score.player1"
        case player2 = "score.player2"
    }

    /// Launches with the default Match setup and an empty Match History.
    private func launch() {
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        app.launch()
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func tap(_ side: Side, times: Int = 1) {
        let target = element(side.rawValue)
        XCTAssertTrue(target.waitForExistence(timeout: 3), "\(side.rawValue) not found")
        for _ in 0..<times {
            target.tap()
        }
    }

    /// Wins games from love. Celebrations don't block taps, so there is no need to wait them out.
    private func winGames(_ side: Side, _ count: Int) {
        tap(side, times: 4 * count)
    }

    /// The game or set banner disappears 1.5s after it appears.
    private func waitForCelebration() {
        Thread.sleep(forTimeInterval: 2)
    }

    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
