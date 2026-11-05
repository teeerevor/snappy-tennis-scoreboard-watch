//
//  LiveScoreboardFeedTests.swift
//  TennisScoringTests
//

import Foundation
import Testing
@testable import TennisScoring

struct LiveScoreboardFeedTests {
    let matchID = UUID()

    /// The Scorer's Match after `points` points to Ana, sent at `second`.
    func update(points: Int, at second: TimeInterval) -> LiveScoreboardMessage {
        var score = MatchScore(rules: MatchRules())
        for _ in 0..<points { score.score(.player1) }
        return LiveScoreboardMessage(
            sentAt: Date(timeIntervalSince1970: second),
            match: LiveMatch(
                id: matchID,
                player1: PlayerInfo(name: "Ana", colorName: "blue"),
                player2: PlayerInfo(name: "Bob", colorName: "green"),
                score: score
            )
        )
    }

    let now = Date(timeIntervalSince1970: 100)

    @Test func showsTheNewestUpdateEvenWhenAnOlderOneArrivesLate() {
        var feed = LiveScoreboardFeed()

        feed.receive(update(points: 2, at: 20))
        feed.receive(update(points: 1, at: 10))

        #expect(feed.match(at: now)?.player1Points == "30")
    }

    @Test func aMatchFromHoursAgoIsNoLongerShown() {
        var feed = LiveScoreboardFeed()
        let threeHoursLater = Date(timeIntervalSince1970: 20 + 3 * 60 * 60)

        feed.receive(update(points: 2, at: 20))

        #expect(feed.match(at: threeHoursLater) == nil)
    }

    @Test func aRainDelayOfHalfAnHourKeepsTheMatchShowing() {
        var feed = LiveScoreboardFeed()
        let halfAnHourLater = Date(timeIntervalSince1970: 20 + 30 * 60)

        feed.receive(update(points: 2, at: 20))

        #expect(feed.match(at: halfAnHourLater)?.player1Points == "30")
    }

    @Test func theScorerLeavingItsMatchClearsTheLiveScoreboard() {
        var feed = LiveScoreboardFeed()
        feed.receive(update(points: 2, at: 20))

        feed.receive(LiveScoreboardMessage(sentAt: Date(timeIntervalSince1970: 30), match: nil))

        #expect(feed.match(at: now) == nil)
    }
}
