//
//  LiveScoreboardMessageTests.swift
//  TennisScoringTests
//

import Foundation
import Testing
@testable import TennisScoring

struct LiveScoreboardMessageTests {
    let ana = PlayerInfo(name: "Ana", colorName: "blue")
    let bob = PlayerInfo(name: "Bob", colorName: "green")

    /// WatchConnectivity only carries property-list dictionaries.
    func throughPropertyList(_ dictionary: [String: Any]) throws -> [String: Any] {
        let data = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .binary, options: 0)
        return try #require(
            try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        )
    }

    @Test func aMatchInProgressSurvivesTheTripToTheLiveScoreboard() throws {
        var score = MatchScore(rules: MatchRules(setsToPlay: 3), isPlayer1Serving: false)
        for _ in 0..<4 { score.score(.player2) }  // Bob holds serve
        score.score(.player1)                     // 15-00 to Ana, Ana serving
        let id = UUID()
        let message = LiveScoreboardMessage(
            sentAt: Date(timeIntervalSince1970: 500),
            match: LiveMatch(id: id, player1: ana, player2: bob, score: score)
        )

        let received = try #require(LiveScoreboardMessage(dictionary: try throughPropertyList(message.dictionary)))

        #expect(received.sentAt == Date(timeIntervalSince1970: 500))
        let match = try #require(received.match)
        #expect(match.id == id)
        #expect(match.player1 == ana)
        #expect(match.player2 == bob)
        #expect(match.player1Points == "15")
        #expect(match.player2Points == "00")
        #expect(match.player1SetScore.prefix(3) == [0, 0, 0])
        #expect(match.player2SetScore.prefix(3) == [1, 0, 0])
        #expect(match.currentSet == 0)
        #expect(match.server == .player1)
        #expect(match.winner == nil)
        #expect(match.rules.setsToPlay == 3)
    }

    @Test func aLongFiveSetMatchStillFitsInOneWatchConnectivityMessage() throws {
        var score = MatchScore(rules: MatchRules(setsToPlay: 5))
        for _ in 0..<1_000 where score.winner == nil {
            score.score(.player1)
            score.score(.player2)
        }
        let message = LiveScoreboardMessage(
            sentAt: .now,
            match: LiveMatch(id: UUID(), player1: ana, player2: bob, score: score)
        )

        let data = try PropertyListSerialization.data(fromPropertyList: message.dictionary, format: .binary, options: 0)

        #expect(data.count < 65_536)
    }

    @Test func theScorerEndingItsMatchClearsTheLiveScoreboard() throws {
        let message = LiveScoreboardMessage(sentAt: Date(timeIntervalSince1970: 9), match: nil)

        let received = try #require(LiveScoreboardMessage(dictionary: try throughPropertyList(message.dictionary)))

        #expect(received.match == nil)
        #expect(received.sentAt == Date(timeIntervalSince1970: 9))
    }

    @Test func otherMessagesAreNotLiveScoreboardUpdates() {
        #expect(LiveScoreboardMessage(dictionary: ["something": "else"]) == nil)
    }

    @Test func aScoreboardIsBetweenGamesOnlyBeforeTheFirstPointOfAGame() {
        var score = MatchScore(rules: MatchRules(setsToPlay: 1))
        let live = { LiveMatch(id: UUID(), player1: ana, player2: bob, score: score) }
        #expect(live().isBetweenGames)          // 0-0, before the first point

        score.score(.player1)
        #expect(!live().isBetweenGames)         // 15-00

        for _ in 0..<3 { score.score(.player1) }
        #expect(live().isBetweenGames)          // Ana won the game, 1-0

        score.score(.player2)
        score.score(.player1)
        #expect(!live().isBetweenGames)         // 15-15
    }

    @Test func aWonMatchIsNotBetweenGames() {
        var score = MatchScore(rules: MatchRules(setsToPlay: 1))
        for _ in 0..<24 { score.score(.player1) }  // 6-0

        let match = LiveMatch(id: UUID(), player1: ana, player2: bob, score: score)

        #expect(match.winner == .player1)
        #expect(!match.isBetweenGames)
    }
}
