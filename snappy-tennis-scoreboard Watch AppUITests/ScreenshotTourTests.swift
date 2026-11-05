//
//  ScreenshotTourTests.swift
//  snappy-tennis-scoreboard Watch AppUITests
//
//  Drives the app through its key screens and keeps a screenshot of each,
//  for review rather than comparison. Run them with scripts/screenshots.sh.
//

import XCTest

@MainActor
final class ScreenshotTourTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Tour

    func test01NewMatchAndMidGame() {
        launch()
        snap("01-new-match")

        tap("score.left", times: 2)
        tap("score.right")
        snap("02-mid-game")
    }

    func test03DeuceAdvantage() {
        launch(settings: ["deuceType": "Long Deuce"])
        tap("score.left", times: 3)
        tap("score.right", times: 3)
        tap("score.left")
        snap("03-deuce-advantage")
    }

    func test04GameCelebration() {
        launch(arguments: ["-holdCelebration"])
        tap("score.left", times: 4)
        XCTAssertTrue(element("celebration").waitForExistence(timeout: 3))
        Thread.sleep(forTimeInterval: 0.5)  // let the word fade in
        snap("04-game-celebration")
    }

    func test05SetScores() {
        launch()
        winGames("score.left", 6)
        waitForScoreboard()
        snap("05-set-scores")
    }

    func test06TieBreak() {
        launch()
        // Server is fixed to the left in static mode, so left/right always mean player 1/2
        winGames("score.left", 5)
        winGames("score.right", 6)
        winGames("score.left", 1)
        waitForScoreboard()
        tap("score.left", times: 3)
        tap("score.right", times: 2)
        snap("06-tiebreak")
    }

    func test07MatchResultAndPlayOn() {
        launch(settings: ["setsToPlay": "1"])
        winGames("score.left", 6)
        XCTAssertTrue(element("result.tapForOptions").waitForExistence(timeout: 5))
        snap("07-match-result")

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        XCTAssertTrue(element("button.playOn").waitForExistence(timeout: 3))
        snap("07b-match-result-options")

        element("button.playOn").tap()
        XCTAssertTrue(element("score.left").waitForExistence(timeout: 3))
        snap("08-play-on")
    }

    func test09ReadableMode() {
        launch(settings: ["displayMode": "Readable"])
        // Player 1 wins a game, so player 2 serves and moves to the left
        winGames("score.left", 1)
        waitForScoreboard()
        tap("score.left")
        snap("09-readable-mode")
    }

    func test10Practice() {
        launch(settings: ["gameMode": "Practice"])
        tap("practice.left", times: 3)
        tap("practice.right", times: 5)
        snap("10-practice")
    }

    func test11Settings() {
        launch()
        element("button.settings").tap()
        Thread.sleep(forTimeInterval: 1)  // sheet animation
        snap("11-settings-top")

        app.swipeUp()
        app.swipeUp()
        Thread.sleep(forTimeInterval: 0.5)
        snap("12-settings-scrolled")
    }

    func test13NewMatch() {
        launch()
        tap("score.left", times: 2)
        tap("button.settings")
        tap("button.newMatch")
        XCTAssertTrue(element("newMatch.swapSides").waitForExistence(timeout: 3), "New Match screen not shown")
        Thread.sleep(forTimeInterval: 0.5)  // push animation
        snap("13-new-match")

        tap("newMatch.swapSides")
        tap("newMatch.swapServer")
        // Start is below the fold, and List rows only exist once scrolled into view
        app.swipeUp()
        Thread.sleep(forTimeInterval: 0.5)
        snap("13b-new-match-choices")

        tap("newMatch.start")
        XCTAssertTrue(element("score.left").waitForExistence(timeout: 3))
        Thread.sleep(forTimeInterval: 1)  // sheet dismissal
        snap("14-new-match-swapped")
    }

    // MARK: - Helpers

    /// Launches with default settings and empty Match History, plus any settings given.
    private func launch(settings: [String: String] = [:], arguments: [String] = []) {
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting"] + arguments
        for (key, value) in settings {
            app.launchEnvironment["UITEST_DEFAULT_\(key)"] = value
        }
        app.launch()
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func tap(_ identifier: String, times: Int = 1) {
        let target = element(identifier)
        XCTAssertTrue(target.waitForExistence(timeout: 3), "\(identifier) not found")
        for _ in 0..<times {
            target.tap()
        }
    }

    /// Wins games from love, waiting out each celebration before the next.
    /// Taps wait for animations to settle, so the celebration is usually over by then.
    private func winGames(_ identifier: String, _ count: Int) {
        for _ in 0..<count {
            tap(identifier, times: 4)
            waitUntilGone(element("celebration"))
        }
    }

    /// The scoreboard updates 1.7s after a celebration starts.
    private func waitForScoreboard() {
        waitUntilGone(element("celebration"))
        Thread.sleep(forTimeInterval: 1.0)
    }

    private func waitUntilGone(_ target: XCUIElement) {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: target)
        XCTAssertEqual(XCTWaiter.wait(for: [gone], timeout: 10), .completed)
    }

    private func snap(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
