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

    // MARK: - Resuming

    /// Wins games from love.
    func win(_ player: Player, games: Int, in session: inout MatchSession) {
        for _ in 0..<(4 * games) { session.scorePoint(player) }
    }

    @Test func resumingAMidMatchRecordPicksUpTheScoreAndServer() throws {
        // Ana takes the first set 6-3, then it's 3-3 in the second, 30-15 to Ana
        var session = newSession()
        win(.player1, games: 4, in: &session)
        win(.player2, games: 3, in: &session)
        win(.player1, games: 2, in: &session)
        win(.player2, games: 3, in: &session)
        win(.player1, games: 3, in: &session)
        session.scorePoint(.player1)
        session.scorePoint(.player1)
        session.scorePoint(.player2)
        let record = try #require(try store.load().first)

        let resumed = MatchSession(resuming: record, history: store)

        #expect(resumed.id == session.id)
        #expect(resumed.player1 == ana)
        #expect(Array(resumed.score.player1SetScore.prefix(2)) == [6, 3])
        #expect(Array(resumed.score.player2SetScore.prefix(2)) == [3, 3])
        #expect(resumed.score.player1Points == "30")
        #expect(resumed.score.player2Points == "15")
        // Ana served game 9, which ended set 1; whoever served a set's last game opens the next,
        // so Ana served games 1, 3 and 5 of set 2 and serves game 7
        #expect(resumed.score.server == .player1)
        #expect(resumed.score.winner == nil)
    }

    @Test func aResumedMatchKeepsSavingUnderTheSameIDAndCanUndoOldPoints() throws {
        var session = newSession()
        session.scorePoint(.player1)
        session.scorePoint(.player2)
        var resumed = MatchSession(resuming: try #require(try store.load().first), history: store)

        resumed.scorePoint(.player1)
        #expect(try store.load().count == 1)
        #expect(try store.load().first?.points.count == 3)

        resumed.undo()
        resumed.undo()
        #expect(resumed.score.player1Points == "15")
        #expect(resumed.score.player2Points == "00")
    }

    @Test func resumingMidTiebreakKeepsTheTiebreakServer() throws {
        // 6-6 in a one-set Match, Ana served first; Bob serves the tiebreak's first point
        var session = newSession(rules: MatchRules(setsToPlay: 1))
        for _ in 0..<6 {
            win(.player1, games: 1, in: &session)
            win(.player2, games: 1, in: &session)
        }
        #expect(session.score.isTieBreak)
        #expect(session.score.server == .player1)
        // After 1 point Bob serves, so after 2 points it's still Bob
        session.scorePoint(.player1)
        session.scorePoint(.player1)

        let resumed = MatchSession(resuming: try #require(try store.load().first), history: store)

        #expect(resumed.score.isTieBreak)
        #expect(resumed.score.player1Points == "02")
        #expect(resumed.score.server == .player2)
        #expect(resumed.score.tieBreakServeCount == 2)
    }

    @Test func resumingWithoutServeTrackingStillScores() throws {
        var session = newSession(server: nil)
        win(.player2, games: 1, in: &session)
        session.scorePoint(.player1)

        let resumed = MatchSession(resuming: try #require(try store.load().first), history: store)

        #expect(resumed.score.tracksServe == false)
        #expect(resumed.score.player2SetScore[0] == 1)
        #expect(resumed.score.player1Points == "15")
    }

    // MARK: - Continue Match

    /// 8 November 2026 at the given UTC time.
    func nov8(_ hour: Int, _ minute: Int = 0, dayOffset: Int = 0) -> Date {
        Calendar.utc.date(from: DateComponents(year: 2026, month: 11, day: 8 + dayOffset, hour: hour, minute: minute))!
    }

    /// Ana wins the first game, then it's 15-30 with Bob serving; the last point is at 23:00.
    func matchLeftAt11pm() -> MatchSession {
        var session = newSession()
        for _ in 0..<4 { session.scorePoint(.player1, at: nov8(22, 50)) }
        session.scorePoint(.player1, at: nov8(22, 55))
        session.scorePoint(.player2, at: nov8(22, 58))
        session.scorePoint(.player2, at: nov8(23, 0))
        return session
    }

    @Test func continuesTheMatchInProgressLaterThatEvening() throws {
        let left = matchLeftAt11pm()

        let continued = try #require(MatchSession(continuing: left.id, history: store, now: nov8(23, 10), calendar: .utc))

        #expect(continued.id == left.id)
        #expect(continued.player1 == ana)
        #expect(continued.score.player1SetScore[0] == 1)
        #expect(continued.score.player1Points == "15")
        #expect(continued.score.player2Points == "30")
        #expect(continued.score.server == .player2)
        #expect(continued.score.canUndo)
    }

    @Test func continuesAfterMidnightUntilTheDayOfTennisEndsAt2am() {
        let left = matchLeftAt11pm()

        #expect(MatchSession(continuing: left.id, history: store, now: nov8(1, 30, dayOffset: 1), calendar: .utc) != nil)
        #expect(MatchSession(continuing: left.id, history: store, now: nov8(2, 0, dayOffset: 1), calendar: .utc) == nil)
    }

    @Test func aWonMatchIsNotContinued() {
        var session = newSession(rules: MatchRules(setsToPlay: 1))
        win(.player1, games: 6, in: &session)
        #expect(session.score.winner == .player1)

        #expect(MatchSession(continuing: session.id, history: store) == nil)
    }

    @Test func aNewMatchWithNoPointsIsNotContinued() {
        let session = newSession()

        #expect(MatchSession(continuing: session.id, history: store) == nil)
    }
}
