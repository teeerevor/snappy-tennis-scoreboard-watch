//
//  MatchHistoryStoreTests.swift
//  TennisScoringTests
//

import Foundation
import Testing
@testable import TennisScoring

struct MatchHistoryStoreTests {
    let store = MatchHistoryStore(
        fileURL: FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("match-history.json")
    )

    func record(id: UUID = UUID(), score: MatchScore) -> MatchRecord {
        MatchRecord(
            id: id,
            startedAt: Date(timeIntervalSince1970: 0),
            updatedAt: Date(timeIntervalSince1970: 60),
            player1: PlayerInfo(name: "Ana", colorName: "blue"),
            player2: PlayerInfo(name: "Bob", colorName: "green"),
            score: score
        )
    }

    @Test func emptyWhenNothingSaved() throws {
        #expect(try store.load().isEmpty)
    }

    @Test func savesAndReloadsAnUnfinishedMatch() throws {
        var score = MatchScore(rules: MatchRules())
        score.score(.player1)
        let saved = record(score: score)

        try store.save(saved)
        let loaded = try store.load()

        #expect(loaded.count == 1)
        #expect(loaded[0].id == saved.id)
        #expect(loaded[0].points.map(\.winner) == [.player1])
        #expect(!loaded[0].isFinished)
    }

    @Test func savingTheSameMatchAgainReplacesIt() throws {
        let id = UUID()
        var score = MatchScore(rules: MatchRules(setsToPlay: 1))
        score.score(.player1)
        try store.save(record(id: id, score: score))

        score.winGames(.player2, 6)
        try store.save(record(id: id, score: score))

        let loaded = try store.load()
        #expect(loaded.count == 1)
        #expect(loaded[0].winner == .player2)
        #expect(loaded[0].isFinished)
    }

    @Test func deleteRemovesOnlyThatMatch() throws {
        let keep = record(score: MatchScore(rules: MatchRules()))
        let remove = record(score: MatchScore(rules: MatchRules()))
        try store.save(keep)
        try store.save(remove)

        try store.delete(id: remove.id)

        #expect(try store.load().map(\.id) == [keep.id])
    }
}
