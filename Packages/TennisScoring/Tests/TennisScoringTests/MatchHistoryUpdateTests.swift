//
//  MatchHistoryUpdateTests.swift
//  TennisScoringTests
//

import Foundation
import Testing
@testable import TennisScoring

struct MatchHistoryUpdateTests {
    let store = MatchHistoryStore(
        fileURL: FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("match-history.json")
    )

    func record(id: UUID = UUID(), score: MatchScore, updatedAt: TimeInterval = 60) -> MatchRecord {
        MatchRecord(
            id: id,
            startedAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: updatedAt),
            player1: PlayerInfo(name: "Ana", colorName: "blue"),
            player2: PlayerInfo(name: "Bob", colorName: "green"),
            score: score
        )
    }

    /// WatchConnectivity only carries property-list dictionaries.
    func throughPropertyList(_ dictionary: [String: Any]) throws -> [String: Any] {
        let data = try PropertyListSerialization.data(fromPropertyList: dictionary, format: .binary, options: 0)
        return try #require(try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
    }

    /// Ana wins 6-4 3-6 6-2.
    func wonThreeSetMatch() -> MatchScore {
        var score = MatchScore(rules: MatchRules(setsToPlay: 3))
        for (winner, games) in [(Player.player1, 4), (.player2, 4), (.player1, 2)] {
            for _ in 0..<(4 * games) { score.score(winner) }
        }
        for (winner, games) in [(Player.player1, 3), (.player2, 6)] {
            for _ in 0..<(4 * games) { score.score(winner) }
        }
        for (winner, games) in [(Player.player2, 2), (.player1, 6)] {
            for _ in 0..<(4 * games) { score.score(winner) }
        }
        return score
    }

    @Test func aWonMatchSurvivesTheTripToTheCompanionApp() throws {
        let won = record(score: wonThreeSetMatch())
        #expect(won.winner == .player1)

        let received = try #require(MatchHistoryUpdate(dictionary: try throughPropertyList(MatchHistoryUpdate.saved(won).dictionary)))
        try store.apply(received)

        let kept = try #require(try store.load().first)
        #expect(kept.id == won.id)
        #expect(kept.player1 == won.player1)
        #expect(kept.points.map(\.winner) == won.points.map(\.winner))
        #expect(Array(kept.player1SetScore.prefix(3)) == [6, 3, 6])
        #expect(Array(kept.player2SetScore.prefix(3)) == [4, 6, 2])
        #expect(kept.isFinished)
    }

    @Test func aLaterVersionOfTheSameMatchReplacesTheEarlierOne() throws {
        let id = UUID()
        var score = MatchScore(rules: MatchRules())
        score.score(.player1)
        try store.apply(.saved(record(id: id, score: score, updatedAt: 60)))
        score.score(.player2)
        try store.apply(.saved(record(id: id, score: score, updatedAt: 90)))

        let kept = try store.load()
        #expect(kept.count == 1)
        #expect(kept[0].points.map(\.winner) == [.player1, .player2])
    }

    @Test func anUpdateArrivingLateDoesNotTakePointsAway() throws {
        let id = UUID()
        var score = MatchScore(rules: MatchRules())
        score.score(.player1)
        let earlier = record(id: id, score: score, updatedAt: 60)
        score.score(.player2)
        try store.apply(.saved(record(id: id, score: score, updatedAt: 90)))

        try store.apply(.saved(earlier))

        #expect(try store.load().first?.points.count == 2)
    }

    @Test func undoingEveryPointRemovesTheMatch() throws {
        let id = UUID()
        var score = MatchScore(rules: MatchRules())
        score.score(.player1)
        try store.apply(.saved(record(id: id, score: score)))

        let received = try #require(MatchHistoryUpdate(dictionary: try throughPropertyList(MatchHistoryUpdate.deleted(id: id).dictionary)))
        try store.apply(received)

        #expect(try store.load().isEmpty)
    }

    @Test func aLiveScoreboardUpdateIsNotAMatchHistoryUpdate() {
        let live = LiveScoreboardMessage(sentAt: .now, match: nil)
        #expect(MatchHistoryUpdate(dictionary: live.dictionary) == nil)
    }
}
