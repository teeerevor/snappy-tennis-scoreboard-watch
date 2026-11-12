//
//  ContinueMatchTests.swift
//  snappy-tennis-scoreboard Watch AppUITests
//
//  watchOS closes the app in the background, often after wrist-down mid-match.
//  The Match in Progress and Practice Session count must be there on relaunch.
//

import XCTest

/// Closing and relaunching the Watch App keeps the Match in Progress and the Practice Session count.
@MainActor
final class ContinueMatchTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testMatchInProgressSurvivesTheAppClosing() {
        launchFresh()
        // Left wins a game, then 30-15
        tap("score.left", times: 4)
        waitUntilGone(element("celebration"))
        waitForLabel("score.left", "00")
        tap("score.left", times: 2)
        tap("score.right")
        waitForLabel("score.left", "30")

        relaunch()

        waitForLabel("score.left", "30")
        XCTAssertEqual(element("score.right").label, "15")
        // Undo still works on points scored before the app closed
        tap("button.undo")
        waitForLabel("score.right", "00")
    }

    func testPracticeCountSurvivesTheAppClosing() {
        launchFresh(settings: ["gameMode": "Practice"])
        tap("practice.left", times: 3)
        tap("practice.right")
        waitForLabel("practice.left", "03")

        relaunch()

        waitForLabel("practice.left", "03")
        XCTAssertEqual(element("practice.right").label, "01")
    }

    // MARK: - Helpers

    private func launchFresh(settings: [String: String] = [:]) {
        app = XCUIApplication()
        app.launchArguments = ["-uiTesting"]
        for (key, value) in settings {
            app.launchEnvironment["UITEST_DEFAULT_\(key)"] = value
        }
        app.launch()
    }

    /// As watchOS does: the process ends, then the app is opened again without the UI-test reset.
    private func relaunch() {
        app.terminate()
        app.launchArguments = []
        app.launchEnvironment = [:]
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

    private func waitUntilGone(_ target: XCUIElement) {
        let gone = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: target)
        XCTAssertEqual(XCTWaiter.wait(for: [gone], timeout: 10), .completed)
    }

    private func waitForLabel(_ identifier: String, _ label: String) {
        let target = element(identifier)
        let matches = expectation(for: NSPredicate(format: "label == %@", label), evaluatedWith: target)
        wait(for: [matches], timeout: 5)
    }
}
