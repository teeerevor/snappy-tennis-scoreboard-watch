//
//  MatchScoreTests.swift
//  TennisScoringTests
//

import Foundation
import Testing
@testable import TennisScoring

extension MatchScore {
    /// Wins a game from love, assuming neither side has points yet.
    @discardableResult
    mutating func winGame(_ player: Player) -> ScoreEvent {
        var event = ScoreEvent.point
        for _ in 0..<4 { event = score(player) }
        return event
    }

    @discardableResult
    mutating func winGames(_ player: Player, _ count: Int) -> ScoreEvent {
        var event = ScoreEvent.point
        for _ in 0..<count { event = winGame(player) }
        return event
    }
}

struct MatchScoreTests {

    @Test func pointsCountUpThroughFortyThenWinTheGame() {
        var match = MatchScore(rules: MatchRules())
        #expect(match.score(.player1) == .point)
        #expect(match.player1Points == "15")
        match.score(.player1)
        #expect(match.player1Points == "30")
        match.score(.player1)
        #expect(match.player1Points == "40")
        #expect(match.score(.player1) == .game)
        #expect(match.player1Points == "00")
        #expect(match.player1SetScore[0] == 1)
    }

    @Test func shortDeuceWinsTheGameFromFortyAll() {
        var match = MatchScore(rules: MatchRules(deuceType: .short))
        for _ in 0..<3 { match.score(.player1); match.score(.player2) }
        #expect(match.player1Points == "40" && match.player2Points == "40")
        #expect(match.score(.player2) == .game)
        #expect(match.player2SetScore[0] == 1)
        #expect(match.player1Points == "00" && match.player2Points == "00")
    }

    @Test func longDeuceGoesThroughAdvantage() {
        var match = MatchScore(rules: MatchRules(deuceType: .long))
        for _ in 0..<3 { match.score(.player1); match.score(.player2) }

        #expect(match.score(.player1) == .point)
        #expect(match.player1Points == "AD" && match.player2Points == "-")

        match.score(.player2)
        #expect(match.player1Points == "40" && match.player2Points == "40")

        match.score(.player2)
        #expect(match.score(.player2) == .game)
        #expect(match.player2SetScore[0] == 1)
    }

    @Test func serveSwitchesAfterEachGame() {
        var match = MatchScore(rules: MatchRules(), isPlayer1Serving: true)
        match.winGame(.player1)
        #expect(match.server == .player2)
        match.winGame(.player2)
        #expect(match.server == .player1)
    }

    @Test func setIsWonSixFour() {
        var match = MatchScore(rules: MatchRules(setsToPlay: 3))
        match.winGames(.player2, 4)
        #expect(match.winGames(.player1, 5) == .game)
        #expect(match.winGame(.player1) == .set)
        #expect(match.player1SetScore[0] == 6)
        #expect(match.currentSet == 1)
    }

    @Test func tieBreakAtSixAllEndsSevenSix() {
        var match = MatchScore(rules: MatchRules(setsToPlay: 3, tieBreakRule: .at66))
        match.winGames(.player1, 5)
        match.winGames(.player2, 6)
        match.winGame(.player1)
        #expect(match.isTieBreak)

        let serverBefore = match.server
        match.score(.player1)
        #expect(match.player1Points == "01")
        #expect(match.server == serverBefore.opponent)  // first server serves one point

        for _ in 0..<5 { match.score(.player1) }
        #expect(match.score(.player1) == .set)
        #expect(match.player1SetScore[0] == 7)
        #expect(match.player2SetScore[0] == 6)
        #expect(match.currentSet == 1)
        #expect(match.tieBreakServeCount == 0)
    }

    @Test(arguments: [0, 1, 2, 3, 4, 5])
    func afterATieBreakTheFirstReceiverServesTheNextSet(loserPoints: Int) {
        var match = MatchScore(rules: MatchRules(setsToPlay: 3, tieBreakRule: .at66))
        match.winGames(.player1, 5)
        match.winGames(.player2, 6)
        match.winGame(.player1)
        #expect(match.isTieBreak)
        let firstReceiver = match.server.opponent

        for _ in 0..<loserPoints { match.score(.player2) }
        var event = ScoreEvent.point
        while event == .point { event = match.score(.player1) }

        #expect(event == .set)
        #expect(match.server == firstReceiver)
    }

    @Test func tieBreakAtFiveAllEndsSixFive() {
        var match = MatchScore(rules: MatchRules(setsToPlay: 1, tieBreakRule: .at55))
        match.winGames(.player1, 4)
        match.winGames(.player2, 5)
        match.winGame(.player1)
        #expect(match.isTieBreak)
        for _ in 0..<6 { match.score(.player2) }
        #expect(match.score(.player2) == .match)
        #expect(match.player2SetScore[0] == 6)
        #expect(match.player1SetScore[0] == 5)
    }

    @Test func noTieBreakNeedsTwoClearGames() {
        var match = MatchScore(rules: MatchRules(setsToPlay: 3, tieBreakRule: .none))
        match.winGames(.player1, 5)
        match.winGames(.player2, 6)
        match.winGame(.player1)
        #expect(!match.isTieBreak)
        #expect(match.winGame(.player1) == .game)
        #expect(match.winGame(.player1) == .set)
        #expect(match.player1SetScore[0] == 8)
    }

    @Test func winningTheMatchSetsTheWinner() {
        var match = MatchScore(rules: MatchRules(setsToPlay: 1))
        #expect(match.winGames(.player2, 6) == .match)
        #expect(match.winner == .player2)
        #expect(match.currentSet == 0)
    }

    @Test func undoRemovesThePointAndTheWin() {
        var match = MatchScore(rules: MatchRules(setsToPlay: 1))
        match.winGames(.player2, 6)
        #expect(match.points.count == 24)

        match.undo()
        #expect(match.winner == nil)
        #expect(match.points.count == 23)
        #expect(match.player2SetScore[0] == 5)
        #expect(match.player2Points == "40")
    }

    @Test func undoWithNoPointsDoesNothing() {
        var match = MatchScore(rules: MatchRules())
        match.undo()
        #expect(match == MatchScore(rules: MatchRules()))
        #expect(!match.canUndo)
    }

    @Test func playOnTurnsOneSetIntoThree() {
        var match = MatchScore(rules: MatchRules(setsToPlay: 1))
        match.winGames(.player1, 6)
        match.playOn()
        #expect(match.rules.setsToPlay == 3)
        #expect(match.currentSet == 1)
        #expect(match.winner == nil)
        #expect(match.points.count == 24)  // still the same Match
    }

    @Test func playOnAfterThirdSetTurnsThreeIntoFive() {
        var match = MatchScore(rules: MatchRules(setsToPlay: 3))
        match.winGames(.player1, 6)
        match.winGames(.player2, 6)
        #expect(match.winGames(.player1, 6) == .match)
        match.playOn()
        #expect(match.rules.setsToPlay == 5)
        #expect(match.currentSet == 3)
    }

    @Test func rulesChangedMidMatchApplyToTheNextPoint() {
        var match = MatchScore(rules: MatchRules(setsToPlay: 3))
        match.winGames(.player1, 5)
        match.rules.setsToPlay = 1
        #expect(match.winGame(.player1) == .match)
    }

    @Test func pointsRecordTheServerOnlyWhenTracked() {
        var match = MatchScore(rules: MatchRules(), isPlayer1Serving: false)
        match.score(.player1)
        #expect(match.points[0].server == .player2)

        match.tracksServe = false
        match.score(.player1)
        #expect(match.points[1].server == nil)
        #expect(match.points.map(\.winner) == [.player1, .player1])
    }
}
