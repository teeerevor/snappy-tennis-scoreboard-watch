//
//  MatchSessionTests.swift
//  TennisScoringTests
//

import Foundation
import Testing
@testable import TennisScoring

struct MatchSessionTests {
    let store = MatchHistoryStore(
        fileURL: FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("match-history.json")
    )

    let ana = PlayerInfo(name: "Ana", colorName: "blue")
    let bob = PlayerInfo(name: "Bob", colorName: "green")

    func newSession(rules: MatchRules = MatchRules(), server: Player? = .player1) -> MatchSession {
        MatchSession(
            player1: ana,
            player2: bob,
            rules: rules,
            server: server,
            history: store,
            now: Date(timeIntervalSince1970: 0)
        )
    }

    @Test func firstPointStartsTheClockAndKeepsAnUnfinishedMatch() throws {
        var session = newSession()

        session.scorePoint(.player1, at: Date(timeIntervalSince1970: 100))
        session.scorePoint(.player2, at: Date(timeIntervalSince1970: 130))

        let saved = try #require(try store.load().first)
        #expect(saved.id == session.id)
        #expect(saved.startedAt == Date(timeIntervalSince1970: 100))
        #expect(saved.updatedAt == Date(timeIntervalSince1970: 130))
        #expect(saved.player1 == ana)
        #expect(saved.points.count == 2)
        #expect(!saved.isFinished)
    }

    @Test func undoKeepsHistoryInStepAndForgetsAMatchWithNoPoints() throws {
        var session = newSession()
        session.scorePoint(.player1)
        session.scorePoint(.player1)

        session.undo()
        #expect(try store.load().first?.points.count == 1)

        session.undo()
        #expect(try store.load().isEmpty)
    }

    @Test func playOnTurnsAFinishedOneSetMatchBackIntoTheSameUnfinishedMatch() throws {
        var session = newSession(rules: MatchRules(setsToPlay: 1))
        var event = ScoreEvent.point
        for _ in 0..<24 { event = session.scorePoint(.player1) }
        #expect(event == .match)
        #expect(try store.load().first?.isFinished == true)

        session.playOn()

        let saved = try store.load()
        #expect(saved.count == 1)
        #expect(saved.first?.id == session.id)
        #expect(saved.first?.isFinished == false)
        #expect(saved.first?.rules.setsToPlay == 3)
    }
}
