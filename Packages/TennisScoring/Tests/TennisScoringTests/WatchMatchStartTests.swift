//
//  WatchMatchStartTests.swift
//  TennisScoringTests
//

import Foundation
import Testing
@testable import TennisScoring

struct WatchMatchStartTests {
    let ana = PlayerInfo(name: "Ana", colorName: "blue")
    let bob = PlayerInfo(name: "Bob", colorName: "green")

    /// WatchConnectivity only carries property-list dictionaries.
    func throughPropertyList(_ dictionary: [String: Any]) throws -> [String: Any] {
        let data = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .binary, options: 0)
        return try #require(
            try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )
    }

    @Test func theMatchSetupSurvivesTheTripToTheWatch() throws {
        let start = WatchMatchStart(
            sentAt: Date(timeIntervalSince1970: 42),
            player1: ana,
            player2: bob,
            rules: MatchRules(setsToPlay: 5, tieBreakRule: .at55, deuceType: .long),
            server: .player2,
            player1OnLeft: false
        )

        let received = try #require(WatchMatchStart(dictionary: try throughPropertyList(start.dictionary)))

        #expect(received == start)
    }

    @Test func aStartAndALiveScoreboardUpdateAreNeverMistakenForEachOther() {
        let start = WatchMatchStart(player1: ana, player2: bob, rules: MatchRules(), server: nil)
        let update = LiveScoreboardMessage(sentAt: .now, match: nil)

        #expect(LiveScoreboardMessage(dictionary: start.dictionary) == nil)
        #expect(WatchMatchStart(dictionary: update.dictionary) == nil)
    }

    @Test func untilTheWatchScoresThePhoneShowsLoveAllWithBobServing() {
        let start = WatchMatchStart(player1: ana, player2: bob, rules: MatchRules(setsToPlay: 3), server: .player2)

        let match = start.placeholder

        #expect(match.id == start.id)
        #expect(match.player1 == ana)
        #expect(match.player2 == bob)
        #expect(match.player1Points == "00")
        #expect(match.player2Points == "00")
        #expect(match.player1SetScore.prefix(3) == [0, 0, 0])
        #expect(match.player2SetScore.prefix(3) == [0, 0, 0])
        #expect(match.server == .player2)
        #expect(match.winner == nil)
    }

    @Test func withoutServeTrackingNobodyIsShownServing() {
        let start = WatchMatchStart(player1: ana, player2: bob, rules: MatchRules(), server: nil)

        #expect(start.placeholder.server == nil)
    }

    @Test func aStartTheWatchOnlyGetsHoursLaterIsIgnored() {
        let sent = Date(timeIntervalSince1970: 0)
        let start = WatchMatchStart(sentAt: sent, player1: ana, player2: bob, rules: MatchRules(), server: nil)

        #expect(!start.isStale(at: sent.addingTimeInterval(10 * 60)))
        #expect(start.isStale(at: sent.addingTimeInterval(3 * 60 * 60)))
    }

    @Test func aStartWithoutSidesPutsPlayer1OnTheLeft() throws {
        let start = WatchMatchStart(player1: ana, player2: bob, rules: MatchRules(), server: .player1, player1OnLeft: false)
        // As sent by a Companion App from before sides could be chosen
        var json = try #require(try JSONSerialization.jsonObject(with: JSONEncoder().encode(start)) as? [String: Any])
        json.removeValue(forKey: "player1OnLeft")
        let older = ["watchMatchStart": try JSONSerialization.data(withJSONObject: json)]

        let received = try #require(WatchMatchStart(dictionary: older))

        #expect(received.player1OnLeft)
        #expect(received.server == .player1)
    }
}
