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

    func test00Home() {
        launch(appearance: "dark")
        XCTAssertTrue(element("button.newMatch").waitForExistence(timeout: 3), "Home not shown")
        snap("00-home-dark")
        launch(appearance: "light")
        XCTAssertTrue(element("button.newMatch").waitForExistence(timeout: 3), "Home not shown")
        snap("00-home-light")
    }

    func test01MidMatch() {
        launch()
        startMatch()
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
        startMatch()
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

    func test06WatchSync() {
        launch(watchSync: true)
        startMatch()
        XCTAssertTrue(element("button.home").waitForExistence(timeout: 3), "Watch Sync not shown")
        snap("06-watch-sync")

        XCUIDevice.shared.orientation = .landscapeLeft
        Thread.sleep(forTimeInterval: 1)  // rotation animation
        snap("07-watch-sync-landscape")

        XCUIDevice.shared.orientation = .portrait
        element("button.home").tap()
        XCTAssertTrue(element("button.continueMatch").waitForExistence(timeout: 3), "Continue Match not shown")
        snap("08-watch-sync-home")
    }

    func test09PlayerColor() {
        launch()
        element("button.newMatch").tap()
        let menu = element("menu.player2Color")
        XCTAssertTrue(menu.waitForExistence(timeout: 3), "Colour menu not shown")
        menu.tap()
        let orange = app.buttons["Orange"]
        XCTAssertTrue(orange.waitForExistence(timeout: 3), "Colours not listed")
        snap("09-player-color-menu")

        orange.tap()
        Thread.sleep(forTimeInterval: 0.5)  // menu closing
        snap("10-player-color-changed")
    }

    func test11HomeWithMatches() {
        launch()
        startMatch()
        winGames(.player1, 12)
        XCTAssertTrue(element("button.playOn").waitForExistence(timeout: 5), "Match result not shown")
        element("button.scorerNewMatch").tap()
        XCTAssertTrue(element("button.start").waitForExistence(timeout: 3), "New Match screen not shown")
        element("button.start").tap()
        winGames(.player2, 2)
        tap(.player1)
        element("button.home").tap()
        XCTAssertTrue(element("button.continueMatch").waitForExistence(timeout: 3), "Continue Match not shown")
        Thread.sleep(forTimeInterval: 0.5)  // navigation animation
        snap("11-home-continue-match")

        XCUIDevice.shared.orientation = .landscapeLeft
        Thread.sleep(forTimeInterval: 1)  // rotation animation
        snap("12-home-landscape")
        XCUIDevice.shared.orientation = .portrait
        Thread.sleep(forTimeInterval: 1)

        element("button.matchHistory").tap()
        Thread.sleep(forTimeInterval: 0.7)
        snap("13-match-history")
        app.navigationBars.buttons.firstMatch.tap()

        element("button.shareMatch").tap()
        Thread.sleep(forTimeInterval: 1.5)  // share sheet
        snap("14-share-match")
    }

    func test15Settings() {
        launch()
        element("button.settings").tap()
        XCTAssertTrue(element("picker.appearance").waitForExistence(timeout: 3), "Settings not shown")
        Thread.sleep(forTimeInterval: 0.5)
        snap("15-settings")
    }

    // MARK: - Helpers

    private enum Side: String {
        case player1 = "score.player1"
        case player2 = "score.player2"
    }

    /// Launches on Home with the default Match setup and an empty Match History.
    private func launch(watchSync: Bool = false, appearance: String = "dark") {
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting", "-appearance", appearance] + (watchSync ? ["-uiTestingWatchSync"] : [])
        app.launch()
    }

    /// From Home, starts a Match with the remembered setup.
    private func startMatch() {
        let newMatch = element("button.newMatch")
        XCTAssertTrue(newMatch.waitForExistence(timeout: 3), "Home not shown")
        newMatch.tap()
        let start = element("button.start")
        XCTAssertTrue(start.waitForExistence(timeout: 3), "New Match screen not shown")
        start.tap()
        Thread.sleep(forTimeInterval: 0.7)  // sheet closing, Match opening
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
